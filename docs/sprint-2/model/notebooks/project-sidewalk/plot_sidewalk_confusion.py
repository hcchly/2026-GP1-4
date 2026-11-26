"""Plot the Project Sidewalk test confusion matrix from results.json.

Usage:
    python plot_sidewalk_confusion.py
    python plot_sidewalk_confusion.py --results results.json --out sidewalk_confusion_test.png
"""
import argparse
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LinearSegmentedColormap

LABELS = ["Damage", "No damage"]   # order used in results.json: [damage, no damage]
DARK = "#1E3D30"
GREEN = "#46B98A"
LIGHT = "#F4FAF7"


def find_test_confusion(obj, path=""):
    """Return the 2x2 confusion matrix stored under a 'test' entry of results.json."""
    if isinstance(obj, dict):
        for key, value in obj.items():
            p = f"{path}/{key}".lower()
            if "confusion" in key.lower() and "test" in p and "baseline" not in p and "majority" not in p:
                m = np.array(value.get("matrix", value.get("rows_true_cols_pred", value)) if isinstance(value, dict) else value)
                if m.shape == (2, 2):
                    return m, p
            found = find_test_confusion(value, p)
            if found:
                return found
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--results", type=Path, default=Path(__file__).with_name("results.json"))
    ap.add_argument("--out", default="sidewalk_confusion_test.png")
    args = ap.parse_args()

    with args.results.expanduser().open(encoding="utf-8") as f:
        results = json.load(f)
    found = find_test_confusion(results)
    if not found:
        raise SystemExit("No 2x2 test confusion matrix found in results.json")
    cm, where = found
    print(f"Using confusion matrix from {where}:\n{cm}  (total {cm.sum()} images)")

    cmap = LinearSegmentedColormap.from_list("khota", [LIGHT, GREEN])
    fig, ax = plt.subplots(figsize=(5.8, 4.7), dpi=300)
    ax.imshow(cm, cmap=cmap, vmin=0, vmax=cm.max())
    for i in range(2):
        for j in range(2):
            v = cm[i, j]
            ax.text(j, i, str(v), ha="center", va="center", fontsize=15, fontweight="bold",
                    color="white" if v / cm.max() > 0.6 else DARK)
    ax.set_xticks([0, 1], LABELS, fontsize=12, color=DARK)
    ax.set_yticks([0, 1], LABELS, fontsize=12, color=DARK)
    ax.set_xlabel("Predicted", fontsize=13, color=DARK)
    ax.set_ylabel("True label", fontsize=13, color=DARK)
    ax.set_title("Project Sidewalk, test set", fontsize=13, color=DARK)
    for s in ax.spines.values():
        s.set_color(DARK)
    ax.set_xticks([0.5], minor=True)
    ax.set_yticks([0.5], minor=True)
    ax.grid(which="minor", color="white", linewidth=2)
    ax.tick_params(which="minor", length=0)
    plt.tight_layout()
    plt.savefig(args.out, facecolor="white")
    print(f"Saved {args.out}")


if __name__ == "__main__":
    main()
