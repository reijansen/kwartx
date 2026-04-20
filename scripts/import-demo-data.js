#!/usr/bin/env node

/**
 * Import Demo Data from JSON into Firebase Firestore
 * 
 * Usage:
 *   node scripts/import-demo-data.js [projectId] [jsonFilePath]
 * 
 * Example:
 *   node scripts/import-demo-data.js kwartx-demo ./scripts/demo-data.json
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const projectId = process.argv[2] || process.env.FIREBASE_PROJECT_ID;
const jsonFilePath = process.argv[3] || './scripts/demo-data.json';

if (!projectId) {
  console.error('❌ Error: Firebase project ID is required');
  console.error('Usage: node scripts/import-demo-data.js <projectId> [jsonFilePath]');
  process.exit(1);
}

console.log(`🔧 Initializing Firebase Admin SDK for project: ${projectId}`);

// Initialize Firebase Admin SDK
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(process.cwd(), 'config', 'firebase-adminsdk.json');

if (!fs.existsSync(serviceAccountPath) && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.warn('⚠️  Using Application Default Credentials');
  admin.initializeApp({
    projectId: projectId,
  });
} else {
  const serviceAccount = require(path.resolve(serviceAccountPath));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: projectId,
  });
}

const db = admin.firestore();

async function importDemoData() {
  try {
    // Read JSON file
    if (!fs.existsSync(jsonFilePath)) {
      console.error(`❌ Error: JSON file not found at ${jsonFilePath}`);
      process.exit(1);
    }

    const rawData = fs.readFileSync(jsonFilePath, 'utf8');
    const data = JSON.parse(rawData);

    console.log('\n📋 Importing demo data from JSON...\n');

    let totalDocuments = 0;

    // Import Users
    if (data.users) {
      console.log('👤 Importing users...');
      for (const [userId, userData] of Object.entries(data.users)) {
        await db.collection('users').doc(userId).set(convertTimestamps(userData));
        totalDocuments++;
      }
      console.log(`✓ Imported ${Object.keys(data.users).length} users`);
    }

    // Import Households
    if (data.households) {
      console.log('🏠 Importing households...');
      for (const [householdId, householdData] of Object.entries(data.households)) {
        await db.collection('households').doc(householdId).set(convertTimestamps(householdData));
        totalDocuments++;
      }
      console.log(`✓ Imported ${Object.keys(data.households).length} households`);
    }

    // Import Household Members
    if (data.household_members) {
      console.log('👥 Importing household members...');
      for (const [memberId, memberData] of Object.entries(data.household_members)) {
        await db.collection('household_members').doc(memberId).set(convertTimestamps(memberData));
        totalDocuments++;
      }
      console.log(`✓ Imported ${Object.keys(data.household_members).length} household members`);
    }

    // Import Expenses
    if (data.expenses && Array.isArray(data.expenses)) {
      console.log('💰 Importing expenses...');
      for (const expenseData of data.expenses) {
        const expenseRef = db.collection('expenses').doc();
        await expenseRef.set({
          ...convertTimestamps(expenseData),
          createdAt: admin.firestore.Timestamp.now(),
        });
        totalDocuments++;
      }
      console.log(`✓ Imported ${data.expenses.length} expenses`);
    }

    // Import Invites
    if (data.invites && Array.isArray(data.invites)) {
      console.log('📬 Importing invites...');
      for (const inviteData of data.invites) {
        await db.collection('invites').add(convertTimestamps(inviteData));
        totalDocuments++;
      }
      console.log(`✓ Imported ${data.invites.length} invites`);
    }

    console.log(`\n✅ Successfully imported ${totalDocuments} documents!\n`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error importing demo data:', error);
    process.exit(1);
  }
}

/**
 * Convert ISO timestamp strings to Firestore Timestamps
 */
function convertTimestamps(obj) {
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(item => convertTimestamps(item));
  }

  if (typeof obj === 'object') {
    const converted = {};
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'string' && isISO8601(value)) {
        converted[key] = admin.firestore.Timestamp.fromDate(new Date(value));
      } else if (typeof value === 'object') {
        converted[key] = convertTimestamps(value);
      } else {
        converted[key] = value;
      }
    }
    return converted;
  }

  return obj;
}

/**
 * Check if string is ISO 8601 timestamp
 */
function isISO8601(str) {
  if (typeof str !== 'string') return false;
  const iso8601Regex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z?$/;
  return iso8601Regex.test(str) && !isNaN(Date.parse(str));
}

// Run the import
importDemoData();
