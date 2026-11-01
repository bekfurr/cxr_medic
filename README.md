# CXR Medic

CXR Medic is a Flutter-based clinical decision support application for chest X-ray (CXR) analysis. It helps clinicians or developers review radiographs, enter patient metadata, and run AI-assisted pathology predictions with fallback to a calibrated offline demo model when a server is unavailable.

## Overview

This project is designed as a cross-platform desktop/mobile clinical workstation for evaluating chest radiographs. The app includes:

- Chest X-ray image upload and default demo radiograph loading
- Patient metadata input: view position, age, and gender
- AI prediction workflow via remote API or offline demo mode
- Pathology card summaries and Grad-CAM-inspired visual explanation
- Server health/status checks and configuration
- A mandatory medical disclaimer flow for clinical use context

The app is built with Flutter and uses Provider for state management.

## Key Features

- Image-based diagnosis workflow for CXR interpretation
- Remote API integration with `/api/v1/health` and `/api/v1/predict`
- Offline demo fallback for cases where the backend is unavailable
- Clinical decision support interface with risk and connection indicators
- Responsive desktop/mobile layouts
- Persistent storage of user preferences and server settings
- Styled medical UI with dark theme and diagnostic panels

## Tech Stack

- Flutter / Dart
- Provider state management
- HTTP client for backend communication
- SharedPreferences for persistent settings
- File picker for selecting local images
- Cross-platform support for Android, iOS, Windows, Linux, macOS, and web

## Project Structure

```text
.
├── android/
├── assets/
├── lib/
│   ├── core/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── test/
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── .metadata
```

### Main application modules

- `lib/main.dart` — app bootstrap and provider setup
- `lib/providers/cdss_provider.dart` — core diagnosis state and logic
- `lib/screens/workstation_screen.dart` — main workstation screen
- `lib/screens/desktop_layout.dart` and `mobile_layout.dart` — responsive layouts
- `lib/services/api_service.dart` — backend prediction and health-check calls
- `lib/services/storage_service.dart` — local config persistence
- `lib/services/mock_diagnosis_service.dart` — fallback simulation for demo/offline mode

## Getting Started

### Prerequisites

- Flutter SDK 3.13.5 or newer
- A supported IDE such as VS Code or Android Studio
- An API backend for prediction responses if using live inference

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Optional: configure backend URL

From the app UI, open the server configuration panel and set your diagnosis backend base URL. The app expects endpoints similar to:

- `GET /api/v1/health`
- `POST /api/v1/predict`

If the backend is unavailable, the app automatically falls back to the offline calibrated demo diagnosis mode.

## App Workflow

1. Open the app and accept the required disclaimer.
2. Select a chest X-ray image or use the demo radiograph.
3. Enter patient metadata such as view position, age, and gender.
4. Connect to the server or use offline demo mode.
5. Run prediction.
6. Review pathology findings and Grad-CAM-inspired visual highlights.

## Notes

This application is intended for research, clinical tooling prototypes, and decision-support demonstrations. It should be used with appropriate medical and software review for any real-world clinical deployment.

## License

This project currently does not specify a public license in the repository metadata. If you plan to share or distribute it publicly, consider adding an explicit license file and license declaration.

## Contributing

Contributions are welcome. For larger changes, please open an issue or start a discussion before submitting a PR.

## Project Status

The repository is structured as a Flutter clinical decision support app with working provider-driven state management, image analysis workflow, and backend integration hooks.
