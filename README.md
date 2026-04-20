# KwartX - Household Expense Splitting App

A modern Flutter + Firebase application for splitting household expenses with roommates. Built for real-world expense management with a focus on simplicity and accuracy.

![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![Platform](https://img.shields.io/badge/Platform-Flutter-blue)
![Backend](https://img.shields.io/badge/Backend-Firebase-orange)

## 📋 Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Demo Setup](#demo-setup)
- [Architecture](#architecture)
- [Database Structure](#database-structure)
- [CRUD Operations](#crud-operations)
- [Troubleshooting](#troubleshooting)

## ✨ Features

### User Management
- Firebase email/password authentication (sign up, sign in, sign out)
- User profile management with full names and email
- Phone number support (Philippines +63 numbers)
- Session persistence across app restarts

### Expense Management
- Create, read, update, delete expenses (full CRUD)
- Multiple expense categories: rent, electricity, water, wifi, groceries, repairs, misc
- Track who paid and who owes
- Flexible expense splitting:
  - Equal split among all participants
  - Exact amount splits
  - Percentage-based splits
  - Custom shares/weights
- Expense notes and timestamps
- Delete functionality (creator only)

### Household Management
- Create and manage households (rooms)
- Invite roommates via email
- Accept/reject invites
- Active membership tracking
- Switch between multiple households

### Settlement & Reporting
- Real-time settlement calculations
- Dashboard with balance summaries
- Pending bills view
- Settlement history
- Text reports for sharing

### UI/UX
- Dark fintech theme with warm orange/cream gradient
- Material 3 design language
- Adaptive layouts (mobile, tablet, web)
- Real-time data sync
- Loading and error states
- Confirmation dialogs for destructive actions

## 🛠️ Requirements

### Development Environment
- **Flutter SDK**: Latest stable version
  ```bash
  flutter --version
  ```
- **Dart SDK**: Included with Flutter
- **Node.js**: v14+ (for seeding scripts)
- **Git**: For version control

### Firebase Project
1. Firebase Authentication
   - Email/Password provider enabled
2. Cloud Firestore
   - Firestore Database enabled in Native mode
   - Region: asia-southeast1 (adjustable)
3. Firebase Storage (optional, for future features)

### Platform Support
- **Android**: API 21+
- **iOS**: 12.0+
- **Web**: Modern browsers (Chrome, Safari, Firefox, Edge)
- **Desktop**: Windows, macOS, Linux

## 📁 Project Structure

```
kwartx/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── firebase_options.dart              # Firebase config
│   ├── constants/
│   │   └── app_constants.dart             # App-wide constants
│   ├── models/
│   │   ├── expense_model.dart             # Expense data model
│   │   ├── expense_participant_model.dart # Split information
│   │   ├── room_model.dart                # Household model
│   │   ├── roommate_model.dart            # Roommate model
│   │   ├── user_profile_model.dart        # User data model
│   │   ├── invite_model.dart              # Invite model
│   │   └── settlement_view_model.dart     # Settlement calculations
│   ├── services/
│   │   ├── firestore_service.dart         # Firestore CRUD & queries
│   │   └── [other services]
│   ├── screens/
│   │   ├── auth_gate_screen.dart          # Auth routing
│   │   ├── landing_screen.dart            # Initial screen
│   │   ├── home_screen.dart               # Main dashboard
│   │   ├── expense_form_screen.dart       # Create/edit expenses
│   │   ├── invite_roommate_screen.dart    # Manage roommates
│   │   ├── profile_screen.dart            # User profile
│   │   ├── analytics_screen.dart          # Reports & analytics
│   │   └── [other screens]
│   ├── theme/
│   │   └── app_theme.dart                 # Material theme config
│   ├── widgets/
│   │   ├── primary_button.dart            # Primary action button
│   │   ├── custom_text_field.dart         # Input field
│   │   ├── dark_card.dart                 # Card component
│   │   ├── app_feedback.dart              # Snackbars & dialogs
│   │   └── [other widgets]
│   └── utils/
│       ├── error_mapper.dart              # Error message mapping
│       └── [other utilities]
├── scripts/
│   ├── seed-demo-complete.js              # Full demo data seeding
│   ├── clean-and-seed-demo.js             # Clean & reseed
│   ├── generate-demo-data.js              # Generate demo data
│   └── package.json                       # Node.js dependencies
├── android/                               # Android-specific code
├── ios/                                   # iOS-specific code
├── web/                                   # Web-specific code
├── test/                                  # Unit & widget tests
├── pubspec.yaml                           # Flutter dependencies
├── firebase.json                          # Firebase config
├── firestore.rules                        # Firestore security rules
├── firestore.indexes.json                 # Firestore indexes
└── README.md                              # This file
```

## 🚀 Quick Start

### 1. Clone & Setup
```bash
git clone https://github.com/yourusername/kwartx.git
cd kwartx
flutter pub get
```

### 2. Firebase Configuration
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-firebase-project
```

### 3. Run the App
```bash
# Development (debug)
flutter run

# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### 4. Verify Setup
```bash
flutter analyze
flutter test
```

## 📊 Demo Setup

### Option A: Quick Demo (Recommended)
```bash
# Generate complete demo data with 3 users, 1 household, 8 expenses, 3 invites
node scripts/seed-demo-complete.js kwartx
```

### Option B: Clean & Reseed
```bash
# Remove old demo data and reseed fresh
node scripts/clean-and-seed-demo.js kwartx
```

### Demo Credentials
After seeding, sign in with any of these accounts:

| Email | Password | Name |
|-------|----------|------|
| john@example.com | Demo@1234 | John Doe |
| sarah@example.com | Demo@1234 | Sarah Smith |
| mike@example.com | Demo@1234 | Mike Johnson |

### Demo Data Included
- **Household**: "Downtown Apartment" with 3 members
- **Expenses**: 8 sample expenses with different categories and splits
- **Invites**: Pending, accepted, and rejected invite examples
- **Splits**: Equal, percentage, exact amount, and shares examples

## 🏗️ Architecture

### MVVM Pattern
```
Views (Screens)
    ↓
ViewModels/States (Stateful Widgets)
    ↓
Services (FirestoreService)
    ↓
Models (ExpenseModel, UserProfileModel, etc.)
    ↓
Firebase Backend
```

### Data Flow
1. User interacts with screen
2. Screen calls service method
3. Service queries Firebase
4. Models parse Firebase data
5. UI rebuilds with new data

## 🗄️ Database Structure

### Collections

#### `users/{uid}`
User profile information
```json
{
  "uid": "user123",
  "fullName": "John Doe",
  "email": "john@example.com",
  "phoneNumber": "+63-917-123-4567",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

#### `households/{householdId}`
Household/room information
```json
{
  "id": "household_abc123",
  "name": "Downtown Apartment",
  "createdBy": "user123",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

#### `household_members/{householdId}_{userId}`
Membership records (active/inactive)
```json
{
  "householdId": "household_abc123",
  "userId": "user123",
  "fullName": "John Doe",
  "email": "john@example.com",
  "status": "active",
  "joinedAt": "2024-01-15T10:30:00Z"
}
```

#### `expenses/{expenseId}`
Expense records
```json
{
  "id": "expense_xyz789",
  "householdId": "household_abc123",
  "title": "Grocery Shopping",
  "amountCents": 12500,  // ₱125.00
  "paidByUserId": "user123",
  "paidByName": "John Doe",
  "createdByUserId": "user123",
  "date": "2024-01-15T10:30:00Z",
  "category": "groceries",
  "splitType": "equal",
  "participantUserIds": ["user123", "user456", "user789"],
  "splitConfig": {},
  "notes": "Weekly grocery run",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

#### `expenses/{expenseId}/expense_participants/{participantId}`
Individual expense splits
```json
{
  "userId": "user456",
  "fullName": "Sarah Smith",
  "exactCents": null,
  "percentageBps": 3333,  // 33.33%
  "shares": null
}
```

#### `invites/{inviteId}`
Roommate invitations
```json
{
  "id": "invite_abc123",
  "householdId": "household_abc123",
  "fromUserId": "user123",
  "toEmail": "newuser@example.com",
  "status": "pending",  // pending, accepted, rejected
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## 🔄 CRUD Operations

### Expenses

#### Create
```dart
final expense = ExpenseModel(
  id: '',  // Firestore will generate
  title: 'Dinner',
  amountCents: 5000,  // ₱50.00
  paidByUserId: 'user123',
  createdByUserId: 'user123',
  date: DateTime.now(),
  category: 'food',
  splitType: 'equal',
  participantUserIds: ['user123', 'user456'],
);

await firestoreService.upsertExpense(
  expense: expense,
  participants: [/* participant models */],
);
```

#### Read
```dart
// Get all expenses for current household (real-time)
Stream<List<ExpenseModel>> expenses = 
  firestoreService.getExpensesStream(uid);

// Get specific expense
DocumentSnapshot doc = await firestore
  .collection('expenses')
  .doc(expenseId)
  .get();
```

#### Update
```dart
await firestoreService.updateExpense(expenseId, {
  'title': 'Updated Dinner',
  'amountCents': 6000,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

#### Delete
```dart
await firestoreService.deleteExpense(expenseId);
```

### Users

#### Create
```dart
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'user@example.com',
  password: 'SecurePassword123!',
);

await firestoreService.createUserProfileAfterSignUp(
  fullName: 'John Doe',
  phoneNumber: '+63-917-123-4567',
);
```

#### Read
```dart
UserProfileModel? profile = 
  await firestoreService.getUserProfile(uid);
```

#### Update
```dart
await firestoreService.updateUserProfile(
  fullName: 'Jane Doe',
  phoneNumber: '+63-921-456-7890',
);
```

### Households

#### Create
```dart
String householdId = await firestoreService.createHousehold(
  name: 'New Apartment',
);
```

#### Read
```dart
List<RoomModel> rooms = 
  await firestoreService.getUserRooms(uid);
```

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

## 🔐 Security

### Firestore Rules
- Users can only read their own profile
- Users can only read expenses in their active household
- Only household members can create/modify expenses
- Invites are private to recipient

### Authentication
- Firebase Auth handles password hashing
- Token-based session management
- Automatic session refresh

## 🐛 Troubleshooting

### Build Issues

**"android/.kotlin" folder errors**
```bash
flutter clean
flutter pub get
flutter run
```

**Firestore index errors**
```
Follow the link in error → Accept Firestore index creation
```

**Firebase not initialized**
```bash
flutterfire configure --project=your-firebase-project
```

### Runtime Issues

**"No active household membership"**
- Sign in
- Create or join a household first
- Try again

**"Expense not loading"**
- Check user is member of household
- Verify Firestore rules
- Check network connection

**Dropdown assertion errors**
- Usually caused by invalid category or user ID in data
- Run `node scripts/clean-and-seed-demo.js kwartx` to reset

### Demo Data Issues

**Duplicate expenses**
```bash
# Clean all demo data and reseed fresh
node scripts/clean-and-seed-demo.js kwartx
```

**Seed script fails**
```bash
# Check Node.js version
node --version  # Should be v14+

# Check Firebase credentials
ls config/

# Install dependencies
cd scripts && npm install
```

## 📱 Platforms

### Windows/Web
```bash
flutter run -d chrome
flutter run -d edge
```

### macOS/iOS
```bash
flutter run -d macos
flutter run -d ios
```

### Android
```bash
flutter run -d android
# or specific device
flutter run -d emulator-5554
```

## 📝 Version History

- **v1.0.0** - Initial release with full CRUD, households, and splits
- **v1.1.0** - Add expense deletion, improve form validation
- **v1.2.0** - Complete demo seeding system

## 🤝 Contributing

Contributions welcome! Please:
1. Create a feature branch
2. Make changes
3. Test thoroughly
4. Submit PR with description

## 📄 License

[Add your license here]

## 👨‍💻 Author

Created for class demos and project submissions.

## 📞 Support

- Check [Troubleshooting](#troubleshooting) section
- Review Firebase Console for errors
- Check Firestore security rules
- Review Android/iOS build logs

---

**Last Updated**: April 2024 | **Version**: 1.2.0
