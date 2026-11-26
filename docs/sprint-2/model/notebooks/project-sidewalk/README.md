# Project Sidewalk Feasibility Experiment

This experiment fine-tuned a pretrained ResNet-18 to classify images from the public Project Sidewalk dataset as **damage** or **no damage**. The checkpoint with the highest validation accuracy was selected for the separate test evaluation.

## Results

| Split | Images | Accuracy | Macro-F1 (0–1) |
| --- | ---: | ---: | ---: |
| Validation | 1,021 | 76.30% | 0.749 |
| Test | 1,024 | 71.29% | 0.696 |

The majority-class baseline predicted damage for every test image and scored **60.55% accuracy** and **0.377 macro-F1**. See the [saved results](results.json) for per-class metrics and confusion matrices, and the [experiment settings](decisions.md) for the training setup.

## Recreate the test plot

Run these commands from this folder to generate `sidewalk_confusion_test.png`.

```bash
python -m pip install matplotlib numpy
python plot_sidewalk_confusion.py
```
