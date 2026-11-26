# Project Sidewalk experiment settings

1. **Label mapping.** The dataset's `label` ClassLabel has names `['correct', 'incorrect']` (index 0, 1). `correct` → **damage** and `incorrect` → **no damage**. Index order is kept: 0 = damage, 1 = no damage.
2. **Majority-class baseline.** The "larger class" is picked from the **train** split only, so no evaluation split affects the choice. It came out as `damage` (2886 of 4766). `damage` is also the larger class in both validation and test. The baseline predicts that one class for every image in validation and test.
3. **Resize.** Images are converted to RGB and resized straight to 224x224 with bilinear interpolation, with no center crop and the aspect ratio not preserved. The images are not cropped.
4. **Preprocessing implementation.** Each image is decoded and resized once and kept in memory as uint8. Random horizontal flips (p = 0.5, train only) and ImageNet normalization are applied to each batch on the device. This gives the same result as torchvision `Resize → RandomHorizontalFlip → ToTensor → Normalize`, but runs faster.
5. **Pretrained weights.** torchvision `ResNet18_Weights.IMAGENET1K_V1`. The final FC layer is replaced with a new 2-output linear layer, and the whole network is fine-tuned.
6. **Optimizer settings.** AdamW uses the PyTorch default weight_decay of 0.01 and default betas. There is no LR scheduler, no class weighting, no early stopping (all 15 epochs run) and no gradient clipping. The loss is plain cross-entropy.
7. **Checkpoint selection.** The checkpoint is the epoch with the highest validation accuracy. On a tie the earlier epoch is kept (strict `>`). Validation metrics in results.json are computed again from that checkpoint after training. The test split is predicted only once, after selection.
8. **Metrics.** Scikit-learn, with `zero_division=0`. This matters for the baseline, where "no damage" is never predicted, so its precision is 0. Confusion matrices have rows = true and columns = predicted, in the order [damage, no damage].
9. **Reproducibility.** Seed 42 is set for Python, NumPy, PyTorch, data shuffling and random flips.
10. **Environment.** Python 3.9.6 was used for training.
11. **Artifacts.** This folder includes the scripts, results and training log. Training saves the selected checkpoint in the output folder.
12. **Selected epoch.** The selected checkpoint was epoch 15, the final training epoch.
