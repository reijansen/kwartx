# KwartX

KwartX is a Flutter + Firebase expense-splitting app for class demos and submissions.

## Features
- Firebase email/password authentication (sign up, sign in, sign out)
- Expense CRUD per authenticated user (`users/{uid}/expenses/{expenseId}`)
- Dashboard totals, filters, search, sorting, and date scopes
- Report preview with lightweight text sharing
- Dark fintech UI theme

## Requirements
- Flutter SDK (stable)
- Firebase project with:
  - Authentication (Email/Password enabled)
  - Cloud Firestore enabled

## Setup
1. Install dependencies
```bash
flutter pub get
```
2. Configure Firebase for your app (if needed)
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
3. Run the app
```bash
flutter run
```

## Verification
```bash
flutter analyze
flutter test
```
