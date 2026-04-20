#!/usr/bin/env node

/**
 * Generate Demo Data for KwartX
 * 
 * Usage:
 *   node scripts/generate-demo-data.js [projectId]
 * 
 * Example:
 *   node scripts/generate-demo-data.js kwartx-demo
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Get project ID from command line or environment
const projectId = process.argv[2] || process.env.FIREBASE_PROJECT_ID;

if (!projectId) {
  console.error('❌ Error: Firebase project ID is required');
  console.error('Usage: node scripts/generate-demo-data.js <projectId>');
  process.exit(1);
}

console.log(`🔧 Initializing Firebase Admin SDK for project: ${projectId}`);

// Initialize Firebase Admin SDK
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(process.cwd(), 'config', 'firebase-adminsdk.json');

if (!fs.existsSync(serviceAccountPath) && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.warn('⚠️  Service account file not found. Using Application Default Credentials.');
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
const now = new Date();

// Demo user IDs (these would be real Firebase Auth UIDs in production)
const USER_1 = 'user_demo_john_001';
const USER_2 = 'user_demo_sarah_002';
const USER_3 = 'user_demo_mike_003';
const HOUSEHOLD_1 = 'household_' + USER_1;

async function generateDemoData() {
  try {
    console.log('\n📋 Generating demo data...\n');

    // 1. Create Users
    console.log('👤 Creating users...');
    await db.collection('users').doc(USER_1).set({
      id: USER_1,
      fullName: 'John Doe',
      email: 'john@example.com',
      phoneNumber: '+1-555-0100',
      householdId: HOUSEHOLD_1,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)),
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    });

    await db.collection('users').doc(USER_2).set({
      id: USER_2,
      fullName: 'Sarah Smith',
      email: 'sarah@example.com',
      phoneNumber: '+1-555-0101',
      householdId: HOUSEHOLD_1,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 25 * 24 * 60 * 60 * 1000)),
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    });

    await db.collection('users').doc(USER_3).set({
      id: USER_3,
      fullName: 'Mike Johnson',
      email: 'mike@example.com',
      phoneNumber: '+1-555-0102',
      householdId: HOUSEHOLD_1,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 20 * 24 * 60 * 60 * 1000)),
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    });
    console.log('✓ Created 3 demo users');

    // 2. Create Household
    console.log('🏠 Creating household...');
    await db.collection('households').doc(HOUSEHOLD_1).set({
      id: HOUSEHOLD_1,
      name: 'Downtown Apartment',
      ownerUid: USER_1,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)),
      updatedAt: admin.firestore.Timestamp.fromDate(now),
    });
    console.log('✓ Created household: Downtown Apartment');

    // 3. Create Household Members
    console.log('👥 Adding household members...');
    const members = [
      { userId: USER_1, fullName: 'John Doe', email: 'john@example.com', role: 'owner' },
      { userId: USER_2, fullName: 'Sarah Smith', email: 'sarah@example.com', role: 'member' },
      { userId: USER_3, fullName: 'Mike Johnson', email: 'mike@example.com', role: 'member' },
    ];

    for (const member of members) {
      await db.collection('household_members').doc(`${HOUSEHOLD_1}_${member.userId}`).set({
        householdId: HOUSEHOLD_1,
        userId: member.userId,
        fullName: member.fullName,
        email: member.email,
        role: member.role,
        status: 'active',
        joinedAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 25 * 24 * 60 * 60 * 1000)),
      });
    }
    console.log('✓ Added 3 household members');

    // 4. Create Expenses
    console.log('💰 Creating expenses...');
    const expenses = [
      {
        title: 'Grocery Shopping',
        amountCents: 12500,
        paidByUserId: USER_1,
        paidByName: 'John Doe',
        date: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
        category: 'groceries',
        splitType: 'equal',
        notes: 'Weekly groceries for the household',
        participants: [USER_1, USER_2, USER_3],
      },
      {
        title: 'Electricity Bill',
        amountCents: 18000,
        paidByUserId: USER_2,
        paidByName: 'Sarah Smith',
        date: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000),
        category: 'utilities',
        splitType: 'equal',
        notes: 'Monthly electricity bill',
        participants: [USER_1, USER_2, USER_3],
      },
      {
        title: 'Internet & Cable',
        amountCents: 9999,
        paidByUserId: USER_3,
        paidByName: 'Mike Johnson',
        date: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000),
        category: 'utilities',
        splitType: 'equal',
        notes: 'Monthly internet and cable subscription',
        participants: [USER_1, USER_2, USER_3],
      },
      {
        title: 'Pizza Night',
        amountCents: 3500,
        paidByUserId: USER_1,
        paidByName: 'John Doe',
        date: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000),
        category: 'food',
        splitType: 'equal',
        notes: 'Friday pizza dinner',
        participants: [USER_1, USER_2, USER_3],
      },
      {
        title: 'Cleaning Supplies',
        amountCents: 4200,
        paidByUserId: USER_2,
        paidByName: 'Sarah Smith',
        date: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000),
        category: 'household',
        splitType: 'equal',
        notes: 'Cleaning products and supplies',
        participants: [USER_1, USER_2, USER_3],
      },
    ];

    for (const expense of expenses) {
      const expenseRef = db.collection('expenses').doc();
      await expenseRef.set({
        householdId: HOUSEHOLD_1,
        title: expense.title,
        amountCents: expense.amountCents,
        paidByUserId: expense.paidByUserId,
        paidByName: expense.paidByName,
        createdByUserId: expense.paidByUserId,
        date: admin.firestore.Timestamp.fromDate(expense.date),
        category: expense.category,
        splitType: expense.splitType,
        participantUserIds: expense.participants,
        notes: expense.notes,
        createdAt: admin.firestore.Timestamp.fromDate(now),
        updatedAt: admin.firestore.Timestamp.fromDate(now),
      });

      // Add expense participants
      for (const participantId of expense.participants) {
        const participantName = participantId === USER_1 ? 'John Doe' : 
                               participantId === USER_2 ? 'Sarah Smith' : 'Mike Johnson';
        const splitAmount = Math.floor(expense.amountCents / expense.participants.length);
        
        await expenseRef.collection('expense_participants').add({
          userId: participantId,
          fullName: participantName,
          exactCents: splitAmount,
          percentageBps: null,
          shares: null,
        });
      }
    }
    console.log('✓ Created 5 demo expenses with participants');

    // 5. Create Sample Invites
    console.log('📬 Creating sample invites...');
    
    // Pending invite
    await db.collection('invites').add({
      senderUid: USER_1,
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
      senderUid: USER_1,
      senderEmail: 'john@example.com',
      senderDisplayName: 'John Doe',
      recipientUid: USER_2,
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
      senderUid: USER_3,
      senderEmail: 'mike@example.com',
      senderDisplayName: 'Mike Johnson',
      recipientEmail: 'rejected@example.com',
      recipientEmailNormalized: 'rejected@example.com',
      status: 'rejected',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000)),
      rejectedAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 9 * 24 * 60 * 60 * 1000)),
    });

    console.log('✓ Created 3 sample invites (pending, accepted, rejected)');

    console.log('\n✅ Demo data generated successfully!\n');
    console.log('📊 Summary:');
    console.log(`   - ${members.length} users created`);
    console.log(`   - 1 household created`);
    console.log(`   - ${members.length} household members added`);
    console.log(`   - ${expenses.length} expenses created`);
    console.log(`   - 3 sample invites created\n`);

    console.log('🔐 Demo Credentials:');
    console.log('   User 1: john@example.com (Owner)');
    console.log('   User 2: sarah@example.com');
    console.log('   User 3: mike@example.com\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error generating demo data:', error);
    process.exit(1);
  }
}

// Run the script
generateDemoData();
