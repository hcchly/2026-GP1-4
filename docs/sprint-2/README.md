# Sprint 2

**Dates:** 26 Oct – 19 Nov 2026
**Code snapshot:** tag [`sprint-2`](https://github.com/hcchly/2026-GP1-4/tree/sprint-2)

## Delivered in the app

- Submit a pedestrian infrastructure report in three steps: photo, location, review
- My Reports: track the status of submitted reports
- Map of submitted reports (OpenStreetMap)
- Cloud Function that keeps the map data up to date
- Cloud Function that sends each new report image to the AI model and stores the results
- Initial system integration: the detected issue class and severity appear in the report details and on the map

## Other Sprint 2 work

- Targeted data collection in Riyadh
- PIQS criteria and weights reviewed and refined
- Issue-detection and severity-classification models trained and evaluated

## Model

The Version 2 model detects Surface Damage and Curb Ramp Issues in sidewalk photos and rates each detection Low–Medium or High. It combines eight detectors (seven YOLO models and one RF-DETR model) with six ResNet-18 severity classifiers, with a detection threshold of 0.15 and a High-severity threshold of 0.29.

- Test results: detection mAP@0.5 of 0.375 and severity macro-F1 of 0.761 on labelled defects
- Feasibility experiments on RDD2022 and Project Sidewalk: [notebooks](model/notebooks/)

Code, weights, and instructions to run the model are in [model](model/).
