# KwartX

KwartX is a Flutter app for shared-expense tracking and splitting.

## Firebase Setup (Standard FlutterFire)

This project uses standard FlutterFire configuration with `lib/firebase_options.dart`.

### 1. Install FlutterFire CLI (once)

```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase for this project

```bash
flutterfire configure
```

This generates/updates:
- `lib/firebase_options.dart`
- platform Firebase config files as needed

### 3. Run the app

```bash
flutter pub get
flutter run
```
