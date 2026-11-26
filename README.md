# Khota | خُطى

Khota is a graduation project at King Saud University. It is a mobile app that lets citizens in Riyadh report sidewalk and curb ramp issues by submitting a photo and location, and then track the status of their reports.

## Goal

Damaged sidewalks and curb ramps are unsafe, especially for wheelchair users, older adults, and parents with strollers. Khota uses AI to identify the defect type and its severity so that the most dangerous problems are fixed first.

## Team Members

- Hala Alduhayan
- Rand Aldahmash
- Rahaf Alshalwi
- Haifa Alromaih

**Supervisor:** Prof. Reham Alabduljabbar

## Release 1 Features

- Account registration, login, logout, password reset, and profile editing
- Three-step report submission: photo, location (GPS or map selection), and review
- My Reports with status filters and report details
- Map of submitted reports using OpenStreetMap
- Arabic (RTL) interface, adjustable font size, and light/dark appearance

Release 1 also includes a first integration of the AI model: after a report is submitted, the detected issue class and severity are shown in the report details and on the map.

Planned for Release 2: PIQS scoring, notifications, and the administrator dashboard.

Model code, weights, and results: `docs/sprint-2/model/`

## Technologies

- Flutter and Dart
- Firebase Authentication, Cloud Firestore, Firebase Storage, and Cloud Functions
- flutter_map and OpenStreetMap (map tiles and Nominatim address lookup)
- Geolocator and camera / image_picker
- AI model: Python 3.11, FastAPI and Uvicorn, PyTorch and torchvision, Ultralytics (YOLOv8 and YOLO26 detectors), RF-DETR, and ResNet-18 severity classifiers

## Requirements

- Flutter SDK (stable channel; Dart version in `pubspec.yaml`)
- Android Studio with an emulator or device, or Xcode with an iOS simulator or device (macOS only)
- Node.js and the Firebase CLI (only for deploying rules and Cloud Functions)
- Python 3.11 and Git LFS (only for running the AI model)

## Setup and Run

1. Clone and enter the project:
   ```bash
   git clone https://github.com/hcchly/2026-GP1-4.git
   cd 2026-GP1-4
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Check the available devices:
   ```bash
   flutter devices
   ```
4. Run the app:
   ```bash
   flutter run
   ```
   Allow camera and location permissions. Camera and GPS may be limited in a web browser.

### Firebase configuration

The app connects to the Khota Firebase project, and the configuration files are included in the repository. To use a different Firebase project, run `flutterfire configure` and replace the generated files.

### Security rules and Cloud Functions (project owners only)

```bash
firebase deploy --only firestore:rules,storage
cd functions-map
npm install
firebase deploy --only functions
cd ../functions-analysis
npm install
cd ..
firebase deploy --config firebase.analysis.json --only functions
```

The `syncKhotaMapReport` function copies each report's location, issue class, severity, and status to the `mapReports` collection. The `analyseKhotaReport` function sends each new report image to the AI model service and stores the detections and severity in the report; set the service address as `KHOTA_API_URL` in `functions-analysis/.env` (see `.env.example`).

### AI model

The model service is in `docs/sprint-2/model/version-2/`. From that folder:

```bash
git lfs pull
python -m pip install -r inference/requirements.txt
python inference/predict.py /path/to/photo.jpg
```

The command prints the detections and severity ratings as JSON. See [the Version 2 model README](docs/sprint-2/model/version-2/README.md) for the results and the API.

## Testing

```bash
flutter test
```

## Project Structure

```
lib/
  screens/      App screens (auth, home, reports, map, profile, settings)
  services/     Firebase, camera, location, and storage services
  widgets/      Shared UI components
test/           Unit and widget tests
functions-map/  Cloud Function that maintains the mapReports collection
functions-analysis/  Cloud Function that sends report images to the AI model
docs/           Documents for each sprint (sprint-0, sprint-1, sprint-2) and the AI model (docs/sprint-2/model/)
AUTHORS         Team members and supervisor
```

## Sprints

- Git tags: `sprint-1` and `sprint-2`
- Sprint documents: `docs/`

## Repository

https://github.com/hcchly/2026-GP1-4
