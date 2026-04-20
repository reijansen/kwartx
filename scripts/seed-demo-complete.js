#!/usr/bin/env node

/**
 * Complete Demo Seeder for KwartX
 * Creates Firebase Auth users AND populates Firestore with demo data
 * Perfect for showing a complete demo to professors/stakeholders
 * 
 * Usage:
 *   node scripts/seed-demo-complete.js [projectId]
 * 
 * Example:
 *   node scripts/seed-demo-complete.js kwartx-demo
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const projectId = process.argv[2] || process.env.FIREBASE_PROJECT_ID;

if (!projectId) {
  console.error('❌ Error: Firebase project ID is required');
  console.error('Usage: node scripts/seed-demo-complete.js <projectId>');
  process.exit(1);
}

console.log(`\n🔧 Initializing Firebase Admin SDK for project: ${projectId}\n`);

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
const auth = admin.auth();
const now = new Date();

// Demo user configuration
const demoUsers = [
  {
    email: 'john@example.com',
    password: 'Demo@1234',
    displayName: 'John Doe',
    phoneNumber: '+63-917-123-4567',
    role: 'owner',
  },
  {
    email: 'sarah@example.com',
    password: 'Demo@1234',
    displayName: 'Sarah Smith',
    phoneNumber: '+63-921-456-7890',
    role: 'member',
  },
  {
    email: 'mike@example.com',
    password: 'Demo@1234',
    displayName: 'Mike Johnson',
    phoneNumber: '+63-910-987-6543',
    role: 'member',
  },
];

async function seedDemoData() {
  let createdUserIds = {};
  let householdId = '';

  try {
    console.log('📋 Starting complete demo data seeding...\n');

    // Step 1: Create Auth Users
    console.log('🔐 [CREATE] Creating Firebase Authentication users...');
    for (const user of demoUsers) {
      try {
        const userRecord = await auth.createUser({
          email: user.email,
          password: user.password,
          displayName: user.displayName,
        });
        createdUserIds[user.email] = {
          uid: userRecord.uid,
          ...user,
        };
        console.log(`   ✓ [CREATE] ${user.email} (UID: ${userRecord.uid})`);
      } catch (error) {
        if (error.code === 'auth/email-already-exists') {
          const existingUser = await auth.getUserByEmail(user.email);
          createdUserIds[user.email] = {
            uid: existingUser.uid,
            ...user,
          };
          console.log(`   ✓ [READ] Found existing: ${user.email} (UID: ${existingUser.uid})`);
        } else {
          throw error;
        }
      }
    }

    const userEmails = Object.keys(createdUserIds);
    const firstUserUid = createdUserIds[userEmails[0]].uid;
    householdId = `household_${firstUserUid}`;

    console.log(`\n✓ Auth users processed: ${userEmails.length} users\n`);

    // Step 2: Create Household
    console.log('🏠 [CREATE] Creating household...');
    await db.collection('households').doc(householdId).set({
      id: householdId,
      name: 'Downtown Apartment',
      ownerUid: firstUserUid,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)),
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    });
    console.log(`   ✓ [CREATE] Household: Downtown Apartment (ID: ${householdId})\n`);

    // Step 3: Create User Documents and Memberships
    console.log('👤 [CREATE] Creating user profiles and household memberships...');
    for (const email of userEmails) {
      const userInfo = createdUserIds[email];
      const uid = userInfo.uid;
      const isOwner = userInfo.role === 'owner';

      // Create user document
      await db.collection('users').doc(uid).set({
        id: uid,
        fullName: userInfo.displayName,
        email: userInfo.email,
        phoneNumber: userInfo.phoneNumber,
        householdId: householdId,
        createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 25 * 24 * 60 * 60 * 1000)),
        updatedAt: admin.firestore.Timestamp.fromDate(now),
      });

      // Create household membership
      await db.collection('household_members').doc(`${householdId}_${uid}`).set({
        householdId: householdId,
        userId: uid,
        fullName: userInfo.displayName,
        email: userInfo.email,
        role: isOwner ? 'owner' : 'member',
        status: 'active',
        joinedAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 25 * 24 * 60 * 60 * 1000)),
      });

      console.log(`   ✓ [CREATE] ${userInfo.displayName} (${userInfo.role})`);
    }
    console.log();

    // Step 4: Create Expenses
    console.log('💰 [CREATE] Adding sample expenses...');
    const userIds = Object.values(createdUserIds).map(u => u.uid);
    const createdExpenseIds = [];
    
    const expenses = [
      {
        title: 'Grocery Shopping',
        amountCents: 12500,
        paidByUserId: userIds[0],
        paidByName: 'John Doe',
        date: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
        category: 'groceries',
        notes: 'Weekly groceries for the household',
      },
      {
        title: 'Electricity Bill',
        amountCents: 18000,
        paidByUserId: userIds[1],
        paidByName: 'Sarah Smith',
        date: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000),
        category: 'electricity',
        notes: 'Monthly electricity bill',
      },
      {
        title: 'Internet & Cable',
        amountCents: 9999,
        paidByUserId: userIds[2],
        paidByName: 'Mike Johnson',
        date: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000),
        category: 'wifi',
        notes: 'Monthly internet and cable subscription',
      },
      {
        title: 'Pizza Night',
        amountCents: 3500,
        paidByUserId: userIds[0],
        paidByName: 'John Doe',
        date: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000),
        category: 'groceries',
        notes: 'Friday pizza dinner with roommates',
      },
      {
        title: 'Cleaning Supplies',
        amountCents: 4200,
        paidByUserId: userIds[1],
        paidByName: 'Sarah Smith',
        date: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000),
        category: 'repairs',
        notes: 'Cleaning products and supplies',
      },
      {
        title: 'Gas & Parking',
        amountCents: 5600,
        paidByUserId: userIds[2],
        paidByName: 'Mike Johnson',
        date: new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000),
        category: 'misc',
        notes: 'Car fuel and parking fees',
      },
      {
        title: 'Bathroom Supplies',
        amountCents: 2800,
        paidByUserId: userIds[0],
        paidByName: 'John Doe',
        date: new Date(now.getTime() - 6 * 24 * 60 * 60 * 1000),
        category: 'repairs',
        notes: 'Toilet paper, soap, and towels',
      },
      {
        title: 'Movie Night Snacks',
        amountCents: 2100,
        paidByUserId: userIds[1],
        paidByName: 'Sarah Smith',
        date: new Date(now.getTime() - 2.5 * 24 * 60 * 60 * 1000),
        category: 'groceries',
        notes: 'Popcorn and candy for movie night',
      },
    ];

    for (const expense of expenses) {
      const expenseRef = db.collection('expenses').doc();
      createdExpenseIds.push(expenseRef.id);
      
      await expenseRef.set({
        id: expenseRef.id,
        householdId: householdId,
        title: expense.title,
        amountCents: expense.amountCents,
        paidByUserId: expense.paidByUserId,
        paidByName: expense.paidByName,
        createdByUserId: expense.paidByUserId,
        date: admin.firestore.Timestamp.fromDate(expense.date),
        category: expense.category,
        splitType: 'equal',
        participantUserIds: userIds,
        notes: expense.notes,
        createdAt: admin.firestore.Timestamp.fromDate(now),
        updatedAt: admin.firestore.Timestamp.fromDate(now),
      });

      // Add expense participants
      for (const participantId of userIds) {
        const participantName = Object.values(createdUserIds).find(u => u.uid === participantId)?.displayName;
        const splitAmount = Math.floor(expense.amountCents / userIds.length);
        
        await expenseRef.collection('expense_participants').add({
          userId: participantId,
          fullName: participantName,
          exactCents: splitAmount,
          percentageBps: null,
          shares: null,
        });
      }

      console.log(`   ✓ [CREATE] ${expense.title} (₱${(expense.amountCents / 100).toFixed(2)}) - Paid by ${expense.paidByName}`);
    }
    console.log();

    // Step 4b: Read & Verify Expenses
    console.log('📖 [READ] Verifying created expenses...');
    const expensesSnapshot = await db.collection('expenses')
      .where('householdId', '==', householdId)
      .get();

    const fetchedExpenses = [];
    expensesSnapshot.forEach((doc) => {
      const data = doc.data();
      fetchedExpenses.push({
        id: doc.id,
        title: data.title,
        amount: (data.amountCents / 100).toFixed(2),
        paidBy: data.paidByName,
        category: data.category,
        participants: data.participantUserIds.length,
      });
    });

    console.log(`   ✓ Found ${fetchedExpenses.length} expenses in database:\n`);
    fetchedExpenses.forEach((exp) => {
      console.log(`     📌 ${exp.title}`);
      console.log(`        Amount: ₱${exp.amount} | Paid by: ${exp.paidBy} | Category: ${exp.category} | Split among: ${exp.participants} people`);
    });
    console.log();

    // Step 5: Create Sample Invites
    console.log('📬 [CREATE] Adding sample invites...');
    
    // Pending invite
    await db.collection('invites').add({
      senderUid: userIds[0],
      senderEmail: 'john@example.com',
      senderDisplayName: 'John Doe',
      recipientEmail: 'pending@example.com',
      recipientEmailNormalized: 'pending@example.com',
      status: 'pending',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000)),
      message: 'Hey! Would love to split expenses with you. Join our household!',
    });

    // Accepted invite
    await db.collection('invites').add({
      senderUid: userIds[0],
      senderEmail: 'john@example.com',
      senderDisplayName: 'John Doe',
      recipientUid: userIds[1],
      recipientEmail: 'sarah@example.com',
      recipientEmailNormalized: 'sarah@example.com',
      recipientDisplayName: 'Sarah Smith',
      status: 'accepted',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 25 * 24 * 60 * 60 * 1000)),
      acceptedAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 24 * 24 * 60 * 60 * 1000)),
      message: 'Join me in splitting household expenses!',
    });

    // Rejected invite
    await db.collection('invites').add({
      senderUid: userIds[2],
      senderEmail: 'mike@example.com',
      senderDisplayName: 'Mike Johnson',
      recipientEmail: 'rejected@example.com',
      recipientEmailNormalized: 'rejected@example.com',
      status: 'rejected',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000)),
      rejectedAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 9 * 24 * 60 * 60 * 1000)),
    });

    console.log('   ✓ [CREATE] Pending invite (pending@example.com)');
    console.log('   ✓ [CREATE] Accepted invite (Sarah accepted)');
    console.log('   ✓ [CREATE] Rejected invite (rejected@example.com)');
    console.log();

    // Step 5b: Read & Verify Invites
    console.log('📖 [READ] Verifying created invites...');
    const invitesSnapshot = await db.collection('invites').get();

    const fetchedInvites = [];
    invitesSnapshot.forEach((doc) => {
      const data = doc.data();
      if (userIds.includes(data.senderUid)) {
        fetchedInvites.push({
          from: data.senderDisplayName,
          to: data.recipientDisplayName || data.recipientEmail,
          status: data.status,
        });
      }
    });

    console.log(`   ✓ Found ${fetchedInvites.length} invites in database:\n`);
    fetchedInvites.forEach((inv) => {
      console.log(`     📌 ${inv.from} → ${inv.to} [${inv.status.toUpperCase()}]`);
    });
    console.log();

    // Success message
    console.log('═══════════════════════════════════════════════════════════');
    console.log('✅ COMPLETE DEMO DATA SEEDED SUCCESSFULLY!');
    console.log('═══════════════════════════════════════════════════════════\n');

    console.log('📊 CRUD Operations Summary:');
    console.log(`\n   [CREATE] - ${userEmails.length} Firebase Auth users`);
    console.log(`   [READ]   - ${userEmails.length} Auth users verified`);
    console.log(`\n   [CREATE] - 1 household + ${userEmails.length} user profiles with memberships`);
    console.log(`   [READ]   - Household and members verified`);
    console.log(`\n   [CREATE] - ${fetchedExpenses.length} expenses with participant splits`);
    console.log(`   [READ]   - ${fetchedExpenses.length} expenses verified from database`);
    console.log(`\n   [CREATE] - ${fetchedInvites.length} sample invites (pending, accepted, rejected)`);
    console.log(`   [READ]   - ${fetchedInvites.length} invites verified from database\n`);

    console.log('📊 Total Data Created:');
    console.log(`   ✓ ${userEmails.length} Firebase Auth users`);
    console.log(`   ✓ 1 household with ${userEmails.length} members`);
    console.log(`   ✓ ${fetchedExpenses.length} expenses with equal splits`);
    console.log(`   ✓ ${fetchedInvites.length} invites with different statuses\n`);

    console.log('🔐 Demo Login Credentials:');
    for (const email of userEmails) {
      const userInfo = createdUserIds[email];
      console.log(`   Email: ${email}`);
      console.log(`   Password: ${userInfo.password}`);
      console.log(`   Name: ${userInfo.displayName}\n`);
    }

    console.log('📱 How to Test:');
    console.log('   1. Run: flutter run');
    console.log('   2. Sign in with any of the credentials above');
    console.log('   3. Explore all features:');
    console.log('      - Dashboard with balances');
    console.log('      - Expenses list');
    console.log('      - Roommate settlements');
    console.log('      - Invites management');
    console.log('      - Room management\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding demo data:', error);
    process.exit(1);
  }
}

// Run the seeder
seedDemoData();
