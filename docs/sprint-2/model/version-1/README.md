# Khota Model – Version 1

Khota v1 identifies two types of defects in sidewalk photos: surface damage and curb ramp issues.

## Detection outputs

| Output | What it describes |
| --- | --- |
| Defect type | Surface damage or a curb ramp issue |
| Bounding box | The location and size of the detected area, normalized to the image dimensions |
| Confidence | A score from 0 to 1 for the individual detection |
| Severity | Low to medium, or high |

## Validation

An automated test checks that the backend reads detections for both defect types from a v1 response and sorts them by confidence.

## Reported detection results

| Defect type | AP@0.5 (%) |
| --- | ---: |
| Surface damage | 17% |
| Curb ramp issues | 61% |

AP@0.5 is average precision at an IoU threshold of 0.5, reported as a percentage. Curb ramp detection scored 44 percentage points higher than surface damage detection.

The [defect detection report](../README.md#test-results) lists these scores under Model 1. Their attribution to v1 is unconfirmed.
