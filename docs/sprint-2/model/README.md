# Khota ML

Khota analyzes sidewalk photos submitted through the app. It detects surface damage and curb ramp issues and assigns a severity rating to each detection.

## Model Versions

- [Version 1](version-1/README.md) provides defect detection and severity classification.
- [Version 2](version-2/README.md) combines eight detectors with six ResNet-18 severity classifiers. On the Riyadh test split, it achieved **0.375 mAP@0.5** for detection and **0.761 macro-F1** for severity classification on labelled defects.

## Feasibility Experiments

The [notebooks folder](notebooks/README.md) contains scripts and results for RDD2022 road damage detection and Project Sidewalk binary damage classification.
