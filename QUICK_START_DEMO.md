# 🚀 Quick Start: Generate Demo Data for KwartX

## The Easiest Way (3 Steps)

### Step 1: Get Your Firebase Service Account Key

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **⚙️ Settings** → **Service Accounts**
4. Click **"Generate New Private Key"**
5. Save the downloaded JSON file to: `config/firebase-adminsdk.json`

```bash
# Create config directory if it doesn't exist
mkdir -p config

# Move your downloaded key file here
cp ~/Downloads/YOUR_KEY_FILE.json config/firebase-adminsdk.json
```

### Step 2: Install Dependencies

```bash
cd scripts
npm install
cd ..
```

### Step 3: Run Demo Data Generator

```bash
# Replace 'your-firebase-project-id' with your actual project ID
node scripts/generate-demo-data.js your-firebase-project-id

# Example:
node scripts/generate-demo-data.js kwartx-demo
```

✅ **Done!** Your database now has demo data.

---

## What Gets Created

### 👥 3 Demo Users
```
john@example.com (Owner)
sarah@example.com
mike@example.com
```

### 🏠 1 Household
- **Downtown Apartment** with all 3 members

### 💰 5 Sample Expenses
- Grocery Shopping: $125.00
- Electricity Bill: $180.00
- Internet & Cable: $99.99
- Pizza Night: $35.00
- Cleaning Supplies: $42.00

All split equally among the 3 members.

### 📬 3 Sample Invites
- 1 Pending (not yet accepted)
- 1 Accepted (already active)
- 1 Rejected (declined)

---

## Testing in Your Flutter App

Once demo data is created:

1. **Find Your Firebase Project ID:**
   - Firebase Console → Project Settings
   - Copy the Project ID

2. **Update `lib/firebase_options.dart`:**
   - Make sure it points to your Firebase project

3. **Update `android/app/google-services.json`:**
   - Download from Firebase Console
   - Place in `android/app/`

4. **Update `ios/Runner/GoogleService-Info.plist`:**
   - Download from Firebase Console
   - Update in Xcode

5. **Run the App:**
   ```bash
   flutter run
   ```

6. **Sign In:**
   - Note: You need to create Firebase Auth accounts
   - See "Create Auth Users" section below

---

## Optional: Create Firebase Auth Users

The demo data creates Firestore documents, but you also need Firebase Auth users to sign in.

### Using Firebase Console

1. Go to **Authentication** in Firebase Console
2. Click **"Create User"** for each:
   - Email: `john@example.com`, Password: `Demo@1234`
   - Email: `sarah@example.com`, Password: `Demo@1234`
   - Email: `mike@example.com`, Password: `Demo@1234`

3. Now you can sign in with these credentials in your app!

---

## Troubleshooting

### Error: "Service account file not found"
```bash
# Make sure the file is in the right place
ls config/firebase-adminsdk.json

# If missing, download again from Firebase Console
```

### Error: "Project ID not found"
```bash
# Provide your project ID explicitly
node scripts/generate-demo-data.js your-actual-project-id

# Find your project ID in Firebase Console → Settings
```

### Error: "Permission denied"
Check your Firestore Security Rules:

**Temporary (for testing only):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /{document=**} {
    allow read, write;
  }
}
```

**Before production:** Use proper authentication rules!

### Need to Clear Data?
```bash
firebase firestore:delete --project=your-project-id --recursive --yes
```

Then run the demo data generator again.

---

## Alternative Methods

### Using Firebase Emulator (Local Only)
```bash
firebase emulators:start
FIREBASE_EMULATOR_HOST=localhost:8080 node scripts/generate-demo-data.js kwartx-dev
```

### Using Batch Import (from JSON)
```bash
node scripts/import-demo-data.js your-project-id scripts/demo-data.json
```

### Manual Setup in Firebase Console
1. Go to Firestore Database
2. Create collections manually:
   - `users`
   - `households`
   - `household_members`
   - `expenses`
   - `invites`
3. Add documents from the JSON structure

---

## Next Steps

✅ Generate demo data (you just did this!)
✅ Create Firebase Auth users
✅ Update Firebase config in Flutter
✅ Test the app
✅ Explore the UI with real data

Happy testing! 🎉
