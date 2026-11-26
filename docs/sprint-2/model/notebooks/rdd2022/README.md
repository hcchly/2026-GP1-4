# RDD2022 Feasibility Experiment

## Multicountry validation

YOLOv8s achieved **F1 57.96%** and **mAP@0.5 56.99%** on **2,359 labelled validation images**. Precision was 60.89% and recall was 55.29% at confidence 0.31 and matching IoU 0.50. See the [results](rerun_results.json) and [run log](rerun.log).

To repeat the evaluation, use Python 3.9.6 and the original dataset package containing `reports/manifest.json`, `dataset/images/val/`, `dataset/labels/val/` and `evaluate_fixed.py`. Run the commands below from this folder.

```bash
python -m pip install torch==2.8.0 torchvision==0.23.0 opencv-python==4.11.0.86 ultralytics==8.4.174
python evaluate.py /path/to/rdd2022-dataset
```

## Separate India test

A different checkpoint was evaluated on **500 test images**. Precision was **45.16%** and recall was **15.79%** at confidence 0.26, with **mAP@0.5 14.65%**. See the [results](india_test_results.json) and [protocol](india_test_protocol.json). The India test data and checkpoint are outside this folder.
