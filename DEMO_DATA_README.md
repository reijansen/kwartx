# 📚 Demo Data Setup - Complete Guide

## 📁 Files Created

I've created a complete demo data generation system for your KwartX app. Here are the files:

### 1. **Main Scripts**
- `scripts/generate-demo-data.js` - Primary Node.js script to generate demo data
- `scripts/import-demo-data.js` - Alternative import script from JSON file
- `scripts/package.json` - NPM dependencies for scripts

### 2. **Data Files**
- `scripts/demo-data.json` - Pre-defined demo data in JSON format

### 3. **Helper Scripts**
- `setup-demo-data.sh` - Linux/Mac shell script (makes setup easy)
- `setup-demo-data.bat` - Windows batch script (makes setup easy)

### 4. **Documentation**
- `QUICK_START_DEMO.md` - 3-step quick start guide (READ THIS FIRST!)
- `DEMO_DATA_SETUP.md` - Comprehensive setup guide with troubleshooting

---

## 🚀 Quick Setup (Pick One)

### Option A: Windows Users (Easiest)
```cmd
# Double-click this file or run in Command Prompt:
setup-demo-data.bat kwartx-demo
```

### Option B: Mac/Linux Users (Easiest)
```bash
chmod +x setup-demo-data.sh
./setup-demo-data.sh kwartx-demo
```

### Option C: Manual (All Platforms)
```bash
# 1. Install dependencies
cd scripts
npm install
cd ..

# 2. Run generator
node scripts/generate-demo-data.js kwartx-demo
```

---

## ⚙️ Setup Prerequisites

Before running any script, you need:

1. **Firebase Project** - Create one at https://console.firebase.google.com
2. **Service Account Key** - Download from Firebase Console:
   - Settings (⚙️) → Service Accounts
   - "Generate New Private Key"
   - Save as `config/firebase-adminsdk.json`
3. **Node.js** - Install from https://nodejs.org

---

## 📊 Demo Data Included

### 👥 Users (3)
```
john@example.com    (Room Owner)
sarah@example.com   (Member)
mike@example.com    (Member)
```

### 🏠 Household (1)
```
Downtown Apartment
├── John Doe (Owner)
├── Sarah Smith (Member)
└── Mike Johnson (Member)
```

### 💰 Expenses (5)
```
Grocery Shopping          $125.00
Electricity Bill          $180.00
Internet & Cable          $99.99
Pizza Night              $35.00
Cleaning Supplies        $42.00
```

All split equally among the 3 members!

### 📬 Invites (3)
```
Pending   (awaiting response)
Accepted  (already joined)
Rejected  (user declined)
```

---

## 🔧 Using Different Methods

### Method 1: Generate New (Recommended)
Generates fresh data with current timestamps:
```bash
node scripts/generate-demo-data.js your-project-id
```

### Method 2: Import from JSON
Uses predefined data from file:
```bash
node scripts/import-demo-data.js your-project-id scripts/demo-data.json
```

### Method 3: Firebase Emulator (Local Testing)
```bash
firebase emulators:start

# In another terminal:
FIREBASE_EMULATOR_HOST=localhost:8080 node scripts/generate-demo-data.js kwartx-dev
```

---

## 🧪 Testing in Your Flutter App

Once demo data is created:

### 1. Update Firebase Config
```bash
# Download from Firebase Console and place these files:
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 2. Create Firebase Auth Users (Optional)
You can sign in with Firestore data alone, but to fully test:
- Go to Firebase Console → Authentication
- Create users:
  - `john@example.com` password: `Demo@1234`
  - `sarah@example.com` password: `Demo@1234`
  - `mike@example.com` password: `Demo@1234`

### 3. Run Your App
```bash
flutter run
```

### 4. Sign In
```
Email: john@example.com
(No password needed if Auth users weren't created)
```

---

## ⚡ Features Available for Testing

After setting up demo data, you can test:

✅ **View Dashboard**
- Balance calculations between users
- Settlement recommendations

✅ **View Expenses**
- List of all expenses
- Category breakdown
- Split details

✅ **Invite System**
- Send invites to new members
- Accept/reject invites
- View pending invites

✅ **Room Management**
- Join rooms
- Switch between rooms
- Leave rooms

✅ **Analytics**
- Expense reports
- Category analysis
- Time period filtering

---

## 🔍 Troubleshooting

### "Project ID not found"
```bash
node scripts/generate-demo-data.js kwartx-demo
```
(Replace `kwartx-demo` with your actual Firebase project ID)

### "Service account not found"
Make sure file exists at:
```
config/firebase-adminsdk.json
```

### "Permission denied"
Temporarily use these Firestore rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /{document=**} {
    allow read, write;
  }
}
```

### "Node.js not found"
Install from https://nodejs.org

---

## 🗑️ Clearing Demo Data

To start fresh:

```bash
# Clear all Firestore data
firebase firestore:delete --project=your-project-id --recursive --yes

# Then regenerate
node scripts/generate-demo-data.js your-project-id
```

---

## 📞 Support

For detailed information, see:
- `QUICK_START_DEMO.md` - Quick setup guide
- `DEMO_DATA_SETUP.md` - Complete reference guide

For issues:
1. Check the troubleshooting section in `DEMO_DATA_SETUP.md`
2. Verify service account file is correct
3. Ensure project ID is correct
4. Check Node.js version: `node --version`

---

## ✅ Next Steps

1. ✓ Read this guide
2. ✓ Follow `QUICK_START_DEMO.md`
3. ✓ Set up service account key
4. ✓ Run demo data generator
5. ✓ Create Firebase Auth users (optional)
6. ✓ Update Flutter app config
7. ✓ Test with `flutter run`

Happy testing! 🎉
