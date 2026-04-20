# KwartX Demo Data Setup

This guide explains how to generate and populate demo data into your Firebase Firestore database.

## Prerequisites

1. **Firebase CLI installed**
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase Admin SDK** (for the Node.js script)
   ```bash
   cd scripts
   npm install firebase-admin
   ```

3. **Firebase Project** - You need a Firebase project created
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project or use an existing one

4. **Service Account Key** (for programmatic access)
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save as `config/firebase-adminsdk.json`

## Option 1: Using Node.js Script (Recommended)

### Setup

```bash
# Install dependencies
cd scripts
npm install firebase-admin

# Copy your service account key
cp ~/Downloads/kwartx-***-adminsdk-***.json ../config/firebase-adminsdk.json
```

### Run

```bash
# From project root
node scripts/generate-demo-data.js your-firebase-project-id

# Example:
node scripts/generate-demo-data.js kwartx-demo
```

### What Gets Created

✅ **3 Demo Users:**
- John Doe (john@example.com) - Room Owner
- Sarah Smith (sarah@example.com)
- Mike Johnson (mike@example.com)

✅ **1 Household/Room:**
- "Downtown Apartment" with all 3 members

✅ **5 Sample Expenses:**
- Grocery Shopping ($125.00) - Split equally
- Electricity Bill ($180.00) - Split equally
- Internet & Cable ($99.99) - Split equally
- Pizza Night ($35.00) - Split equally
- Cleaning Supplies ($42.00) - Split equally

✅ **3 Sample Invites:**
- 1 Pending invite
- 1 Accepted invite
- 1 Rejected invite

## Option 2: Using Firebase Emulator (Local Testing)

### Start the Emulator

```bash
# Install emulator
firebase init emulator

# Start emulator
firebase emulators:start

# In another terminal, run demo data script
FIREBASE_EMULATOR_HOST=localhost:8080 node scripts/generate-demo-data.js kwartx-dev
```

## Option 3: Using Firestore UI / Console

Manually add documents via Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → Firestore Database
3. Create collections and documents according to the schema

## Option 4: Using Firebase CLI Batch Import

```bash
# Export demo data to JSON first
firebase firestore:delete --project=your-project-id --recursive --yes

# Then import using the script
node scripts/generate-demo-data.js your-project-id
```

## Testing in Flutter App

Once demo data is created:

1. **Update Firebase Configuration:**
   - Ensure `lib/firebase_options.dart` points to your Firebase project
   - Update `google-services.json` for Android

2. **Run the App:**
   ```bash
   flutter run
   ```

3. **Sign In with Demo Account:**
   - Email: `john@example.com`
   - Password: (Use Firebase Auth - set up a test account first)

## Optional: Create Test Auth Users

Since the script only creates Firestore data, you need to create Firebase Auth users separately:

```bash
# Using Firebase CLI
firebase auth:import users.json

# Or manually in Firebase Console:
# Authentication → Users → Add User
# - Email: john@example.com
# - Password: demo1234
```

## Troubleshooting

### "Service account file not found"
```bash
# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="./config/firebase-adminsdk.json"
```

### "Project ID not found"
```bash
# Provide project ID explicitly
node scripts/generate-demo-data.js your-firebase-project-id
```

### "Permission denied" on Firestore
- Ensure your Firestore rules allow the operation
- Check that your service account has proper roles in IAM
- Temporarily use test mode: `match /{document=**} { allow read, write; }`

### Need to Clear All Data?
```bash
firebase firestore:delete --project=your-project-id --recursive --yes
```

## Data Structure

The demo data follows this Firestore structure:

```
├── users/
│   ├── user_demo_john_001
│   ├── user_demo_sarah_002
│   └── user_demo_mike_003
├── households/
│   └── household_user_demo_john_001
├── household_members/
│   ├── household_user_demo_john_001_user_demo_john_001
│   ├── household_user_demo_john_001_user_demo_sarah_002
│   └── household_user_demo_john_001_user_demo_mike_003
├── expenses/
│   ├── [expense_1]
│   ├── [expense_2]
│   └── expense_participants/
│       ├── [participant_1]
│       └── [participant_2]
└── invites/
    ├── [invite_1]
    ├── [invite_2]
    └── [invite_3]
```

## Next Steps

1. ✅ Set up service account
2. ✅ Run demo data script
3. ✅ Create Firebase Auth test users
4. ✅ Configure Flutter app with Firebase
5. ✅ Test the app with demo data

For more info, see the [Firebase Documentation](https://firebase.google.com/docs/firestore/quickstart).
