# Khota Feasibility Experiments

This archive contains the scripts and saved results for two feasibility experiments on public datasets. Khota's final model was evaluated separately on the Riyadh dataset.

- [RDD2022](rdd2022/README.md) uses YOLOv8s to detect road damage. The [validation results](rdd2022/rerun_results.json) cover 2,359 labelled images. The folder also includes the checkpoint, evaluation script, run log, and [results from a separate India test run](rdd2022/india_test_results.json). Repeating the validation evaluation requires the original dataset package described in the RDD2022 README.
- [Project Sidewalk](project-sidewalk/decisions.md) uses ResNet-18 to classify sidewalk images as damage or no damage. The [saved results](project-sidewalk/results.json) include the validation and test metrics and confusion matrices. Retraining requires access to the dataset and pretrained weights.

## Results

| Experiment | Split | Images | Results |
| --- | --- | ---: | --- |
| RDD2022 multicountry (YOLOv8s) | Validation | 2,359 | Precision 60.89%, recall 55.29%, F1 57.96%, mAP@0.5 56.99% |
| RDD2022 India (separate checkpoint) | Test | 500 | Precision 45.16%, recall 15.79%, F1 23.40%, mAP@0.5 14.65% |
| Project Sidewalk (ResNet-18) | Validation | 1,021 | Accuracy 76.30%, macro-F1 0.749 |
| Project Sidewalk (ResNet-18) | Test | 1,024 | Accuracy 71.29%, macro-F1 0.696 |

The Project Sidewalk majority-class baseline scored 60.55% accuracy and 0.377 macro-F1 on the test split.

## Recreate the Project Sidewalk test plot

From the extracted `notebooks` folder, install the plotting libraries and run:

```bash
python -m pip install matplotlib numpy
python project-sidewalk/plot_sidewalk_confusion.py
```

This writes `sidewalk_confusion_test.png` using the saved test results.
