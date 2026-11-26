# RDD2022 validation

This folder records a CPU validation rerun of the YOLOv8s checkpoint from the Colab run `s640`. See the [rerun results](rerun_results.json) for the metrics, [original validation results](original_validation.json) for the reference run, and [rerun log](rerun.log) for the console output.

The rerun used 2,359 validation images and 5,480 labelled boxes. The evaluation used an image size of 960 px and a batch size of 4. Precision, recall and F1 used a confidence threshold of 0.31 and a matching IoU of 0.50. NMS used an IoU of 0.70 and a maximum of 300 detections. Test-time augmentation was disabled.

## Re-run the evaluation

The [evaluation script](evaluate.py) and checkpoint `best.pt` are included. To run the evaluation, you also need the original dataset package with `reports/manifest.json`, `dataset/images/val/`, `dataset/labels/val/` and `evaluate_fixed.py`. The dataset package and Colab notebook are outside this repository.

The rerun used Python 3.9.6. With the original dataset package available, run these commands from this folder:

```bash
python -m pip install torch==2.8.0 torchvision==0.23.0 opencv-python==4.11.0.86 ultralytics==8.4.174
python evaluate.py /path/to/rdd2022-dataset
```

The script verifies the checkpoint, manifest, images and labels by SHA-256 and writes the rerun metrics to `rerun_results.json`.

## Separate India test evaluation

The India-only test run used a different checkpoint on 500 images with 1,064 labelled boxes. The [saved results](india_test_results.json) show precision **45.16%**, recall **15.79%** and F1 **23.40%** at confidence 0.26 and matching IoU 0.50. **mAP@0.5 was 14.65%**, measured by the Ultralytics evaluator. The [protocol](india_test_protocol.json) records the checkpoint hash and settings. The [Ultralytics output](india_test_ultralytics.json) reports its own precision and recall at a different operating point. The India test checkpoint and dataset are outside this repository.
