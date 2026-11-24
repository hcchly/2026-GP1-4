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

Planned for Release 2: AI severity assessment, PIQS scoring, notifications, and the administrator dashboard.

Model documents: `docs/sprint-2/model/`

## Technologies

- Flutter and Dart
- Firebase Authentication, Cloud Firestore, Firebase Storage, and Cloud Functions
- flutter_map and OpenStreetMap (map tiles and Nominatim address lookup)
- Geolocator and camera / image_picker

## Requirements

- Flutter SDK (stable channel; Dart version in `pubspec.yaml`)
- Android Studio with an emulator or device, or Xcode with an iOS simulator or device (macOS only)
- Node.js and the Firebase CLI (only for deploying rules and Cloud Functions)

## Setup and Run

1. Clone and enter the project:
   ```bash
   git clone https://github.com/hcchly/2026-GP1-Group4.git
   cd 2026-GP1-Group4
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
```

The `syncKhotaMapReport` function copies each report's location, issue class, severity, and status to the `mapReports` collection.

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
docs/           Documents for each sprint (sprint-0, sprint-1, sprint-2)
AUTHORS         Team members and supervisor
```

## Sprints

- Git tags: `sprint-1` and `sprint-2`
- Sprint documents: `docs/`

## Repository

https://github.com/hcchly/2026-GP1-Group4
