# Khota ML

Khota is our graduation project at King Saud University. The app lets people report sidewalk problems in Riyadh using photos.

## Model 1 - Defect Detection

We use seven YOLO detectors to find curb ramp issues and surface damage. The pipeline combines overlapping predictions for the same type of defect and returns a bounding box and confidence score for each detection.

### Test results

The test photos came from locations that were not used for training.

| What we measured | Result |
| --- | ---: |
| Curb ramp issue detection (AP@0.5) | 61% |
| Surface damage detection (AP@0.5) | 17% |
| Photos with a labeled defect that got at least one detection | 56% |
| Photos without a labeled defect that got a false alarm | 9% |

The model did better at finding curb ramp issues than surface damage. Surface damage is the main area we want to improve.

### Files

- [`khota/ensemble.py`](khota/ensemble.py) combines predictions from the detectors.
- [`weights/pipeline.json`](weights/pipeline.json) contains the model settings.
- [`examples/sample_response.json`](examples/sample_response.json) shows an example prediction with bounding boxes and confidence scores.
