"""Project Sidewalk surface-problem feasibility rerun: binary damage vs no-damage.

ResNet-18 (ImageNet weights), 224x224, ImageNet normalization, horizontal flip only,
AdamW lr 3e-4, batch 32, up to 15 epochs, keep epoch with best validation accuracy, seed 42.
Test split is evaluated exactly once, at the end, with the selected checkpoint.
"""
import copy
import json
import os
import platform
import random
import sys
import time
from collections import Counter

import numpy as np
import torch
import torch.nn as nn
import torchvision
from datasets import load_dataset
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_recall_fscore_support
from torchvision.models import ResNet18_Weights, resnet18

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET = "projectsidewalk/sidewalk-validator-ai-dataset-surfaceproblem"
SEED = 42
IMG = 224
BATCH = 32
LR = 3e-4
EPOCHS = 15
MEAN = [0.485, 0.456, 0.406]
STD = [0.229, 0.224, 0.225]
# Source label name -> task class name. "correct" = the surface problem is real = damage.
NAME_MAP = {"correct": "damage", "incorrect": "no damage"}


def log(msg):
    print(msg, flush=True)


def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


def to_tensor_uint8(split):
    """Decode each image once, convert to RGB, resize to 224x224 (bilinear), store as uint8."""
    xs = np.empty((len(split), 3, IMG, IMG), dtype=np.uint8)
    for i, ex in enumerate(split):
        im = ex["image"].convert("RGB").resize((IMG, IMG), resample=2)  # 2 = BILINEAR
        xs[i] = np.asarray(im, dtype=np.uint8).transpose(2, 0, 1)
    return torch.from_numpy(xs)


def batches(n, shuffle, gen):
    idx = torch.randperm(n, generator=gen) if shuffle else torch.arange(n)
    for s in range(0, n, BATCH):
        yield idx[s:s + BATCH]


def prep(xb, device, mean, std, train, gen):
    xb = xb.to(device).float().div_(255.0)
    if train:  # random horizontal flip, p=0.5 per image
        flip = torch.rand(xb.shape[0], generator=gen) < 0.5
        if flip.any():
            fi = flip.nonzero().flatten().to(device)
            xb[fi] = xb[fi].flip(-1)
    return (xb - mean) / std


@torch.no_grad()
def predict(model, X, device, mean, std):
    model.eval()
    preds = []
    for b in batches(len(X), False, None):
        logits = model(prep(X[b], device, mean, std, False, None))
        preds.append(logits.argmax(1).cpu())
    return torch.cat(preds).numpy()


def metrics(y_true, y_pred, class_names):
    labels = list(range(len(class_names)))
    p, r, f, sup = precision_recall_fscore_support(y_true, y_pred, labels=labels, zero_division=0)
    return {
        "n": int(len(y_true)),
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "macro_f1": float(f1_score(y_true, y_pred, labels=labels, average="macro", zero_division=0)),
        "per_class": {
            class_names[k]: {"precision": float(p[k]), "recall": float(r[k]), "f1": float(f[k]), "support": int(sup[k])}
            for k in labels
        },
        "confusion_matrix": {
            "labels_order": class_names,
            "rows_true_cols_pred": confusion_matrix(y_true, y_pred, labels=labels).tolist(),
        },
    }


def main():
    t0 = time.time()
    set_seed(SEED)
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    log(f"device={device} torch={torch.__version__} torchvision={torchvision.__version__} python={sys.version.split()[0]}")

    ds = load_dataset(DATASET)
    log(str(ds))
    src_names = ds["train"].features["label"].names
    class_names = [NAME_MAP[n] for n in src_names]
    log(f"source label names (index order): {src_names}")
    log(f"task class names (index order): {class_names}")

    label_counts = {}
    for split in ["train", "validation", "test"]:
        c = Counter(ds[split]["label"])
        label_counts[split] = {
            class_names[k]: {"source_label": src_names[k], "index": k, "count": int(c.get(k, 0))}
            for k in range(len(src_names))
        }
        label_counts[split]["total"] = int(len(ds[split]))
        log(f"{split} label counts: " + ", ".join(
            f"{class_names[k]} ({src_names[k]}, idx {k}) = {c.get(k, 0)}" for k in range(len(src_names))
        ) + f" | total = {len(ds[split])}")

    log("decoding + resizing images to 224x224 ...")
    X = {s: to_tensor_uint8(ds[s]) for s in ["train", "validation", "test"]}
    Y = {s: np.asarray(ds[s]["label"], dtype=np.int64) for s in ["train", "validation", "test"]}
    log(f"images ready ({time.time() - t0:.0f}s)")

    # Majority-class baseline: the larger class is chosen from the TRAIN split only.
    train_counts = Counter(Y["train"].tolist())
    majority = max(train_counts, key=lambda k: train_counts[k])
    log(f"majority class (from train) = {class_names[majority]} (idx {majority})")

    mean = torch.tensor(MEAN, device=device).view(1, 3, 1, 1)
    std = torch.tensor(STD, device=device).view(1, 3, 1, 1)

    model = resnet18(weights=ResNet18_Weights.IMAGENET1K_V1)
    model.fc = nn.Linear(model.fc.in_features, len(class_names))
    model.to(device)
    opt = torch.optim.AdamW(model.parameters(), lr=LR)
    crit = nn.CrossEntropyLoss()
    gen = torch.Generator().manual_seed(SEED)

    Xtr, Ytr = X["train"], torch.from_numpy(Y["train"])
    history = []
    best_acc, best_epoch, best_state = -1.0, None, None
    for ep in range(1, EPOCHS + 1):
        te = time.time()
        model.train()
        tot_loss, tot_correct, tot_n = 0.0, 0, 0
        for b in batches(len(Xtr), True, gen):
            xb = prep(Xtr[b], device, mean, std, True, gen)
            yb = Ytr[b].to(device)
            opt.zero_grad(set_to_none=True)
            out = model(xb)
            loss = crit(out, yb)
            loss.backward()
            opt.step()
            tot_loss += loss.item() * len(b)
            tot_correct += (out.argmax(1) == yb).sum().item()
            tot_n += len(b)
        vpred = predict(model, X["validation"], device, mean, std)
        vacc = float(accuracy_score(Y["validation"], vpred))
        vf1 = float(f1_score(Y["validation"], vpred, average="macro"))
        improved = vacc > best_acc
        if improved:
            best_acc, best_epoch = vacc, ep
            best_state = copy.deepcopy({k: v.detach().cpu() for k, v in model.state_dict().items()})
        rec = {"epoch": ep, "train_loss": tot_loss / tot_n, "train_acc": tot_correct / tot_n,
               "val_acc": vacc, "val_macro_f1": vf1, "best_so_far": improved, "seconds": time.time() - te}
        history.append(rec)
        log(f"epoch {ep:2d} | train_loss {rec['train_loss']:.4f} train_acc {rec['train_acc']:.4f} | "
            f"val_acc {vacc:.4f} val_macro_f1 {vf1:.4f} | {rec['seconds']:.0f}s{' *best*' if improved else ''}")

    log(f"selected epoch {best_epoch} (best val acc {best_acc:.4f})")
    model.load_state_dict(best_state)
    torch.save(best_state, os.path.join(OUT_DIR, "best_model.pt"))

    results_eval = {}
    baselines = {}
    for split in ["validation", "test"]:  # test evaluated exactly once, here
        pred = predict(model, X[split], device, mean, std)
        results_eval[split] = metrics(Y[split], pred, class_names)
        base_pred = np.full_like(Y[split], majority)
        bm = metrics(Y[split], base_pred, class_names)
        baselines[split] = {"predicts": class_names[majority], "accuracy": bm["accuracy"],
                            "macro_f1": bm["macro_f1"], "per_class": bm["per_class"],
                            "confusion_matrix": bm["confusion_matrix"]}
        m = results_eval[split]
        log(f"[{split}] model acc {m['accuracy']:.4f} macro-F1 {m['macro_f1']:.4f} | "
            f"baseline acc {bm['accuracy']:.4f} macro-F1 {bm['macro_f1']:.4f}")
        for cn, pc in m["per_class"].items():
            log(f"[{split}]   {cn:9s} P {pc['precision']:.4f} R {pc['recall']:.4f} F1 {pc['f1']:.4f} n {pc['support']}")
        log(f"[{split}]   confusion (rows true, cols pred, order {class_names}): {m['confusion_matrix']['rows_true_cols_pred']}")

    results = {
        "task": "binary damage vs no damage (Project Sidewalk surface problem validation)",
        "dataset": DATASET,
        "label_mapping": {src: NAME_MAP[src] for src in src_names},
        "class_index_order": class_names,
        "label_counts": label_counts,
        "settings": {
            "model": "resnet18", "weights": "torchvision ResNet18_Weights.IMAGENET1K_V1",
            "image_size": [IMG, IMG], "resize": "direct bilinear resize to 224x224 (no crop), RGB",
            "normalization": {"mean": MEAN, "std": STD}, "augmentation": "random horizontal flip p=0.5 (train only)",
            "optimizer": "AdamW", "lr": LR, "weight_decay": opt.param_groups[0]["weight_decay"],
            "batch_size": BATCH, "max_epochs": EPOCHS, "loss": "cross-entropy (unweighted)",
            "selection": "epoch with best validation accuracy (first epoch on ties)",
            "seed": SEED, "device": str(device), "torch": torch.__version__,
            "torchvision": torchvision.__version__, "python": sys.version.split()[0],
            "platform": platform.platform(),
        },
        "selected_epoch": best_epoch,
        "training_history": history,
        "validation": results_eval["validation"],
        "test": results_eval["test"],
        "majority_baseline": {"majority_class_chosen_from": "train", **baselines},
        "runtime_seconds": time.time() - t0,
    }
    with open(os.path.join(OUT_DIR, "results.json"), "w") as f:
        json.dump(results, f, indent=2)
    log(f"saved {os.path.join(OUT_DIR, 'results.json')}")


if __name__ == "__main__":
    main()
