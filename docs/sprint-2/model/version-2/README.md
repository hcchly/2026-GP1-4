# Khota Model v2

Khota v2 detects surface damage and curb ramp issues in sidewalk photos. For each detection, it returns a bounding box, a confidence score, and a severity rating of Low–Medium or High. The pipeline combines eight detectors with six ResNet-18 severity classifiers.

## Results

The model was evaluated on the Riyadh dataset, split by location.

| Metric | Validation (104 photos) | Test (103 photos) |
| --- | ---: | ---: |
| Detection mAP@0.5 | 0.446 | 0.375 |
| Severity macro-F1 on labelled defects | 0.788 | 0.761 |

On the test split, the full pipeline flagged 63 of 71 photos with a labelled defect and 7 of 32 photos without one. See the [validation results](https://github.com/halaalduh/FINAL-MODEL-KHOTA/blob/9a075a34d7c24665854813e73aaa8cd08569082a/results/val_metrics_v2.json) and [test results](https://github.com/halaalduh/FINAL-MODEL-KHOTA/blob/9a075a34d7c24665854813e73aaa8cd08569082a/results/test_metrics_v2.json).

## Run locally

Use Python 3.11. With Git LFS installed, run `git lfs pull` from the repository root to download the weights. Install PyTorch and torchvision using the CPU or CUDA instructions in [requirements.txt](inference/requirements.txt). Then run these commands from `version-2/`:

```bash
python -m pip install -r inference/requirements.txt
python inference/predict.py /path/to/photo.jpg
```

The command prints the detections and severity ratings as JSON.
