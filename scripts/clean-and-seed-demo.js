#!/usr/bin/env node

/**
 * Clean Demo Data & Reseed
 * Removes all demo expenses/invites for the household, then reseeds fresh
 * 
 * Usage:
 *   node scripts/clean-and-seed-demo.js [projectId]
 * 
 * Example:
 *   node scripts/clean-and-seed-demo.js kwartx
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const projectId = process.argv[2] || process.env.FIREBASE_PROJECT_ID;

if (!projectId) {
  console.error('❌ Error: Firebase project ID is required');
  console.error('Usage: node scripts/clean-and-seed-demo.js <projectId>');
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
const now = new Date();

// John's UID (first user created in seeder)
const JOHN_UID = 'oH04YBmH80egn5YPJzxaYoB18r83';
const HOUSEHOLD_ID = `household_${JOHN_UID}`;

async function cleanAndReseed() {
  try {
    console.log('📋 Starting clean and reseed...\n');

    // Step 1: Delete all expenses for this household
    console.log('🗑️  [DELETE] Removing existing expenses...');
    const expensesSnapshot = await db.collection('expenses')
      .where('householdId', '==', HOUSEHOLD_ID)
      .get();

    let deletedCount = 0;
    for (const doc of expensesSnapshot.docs) {
      // Delete participants first
      const participantsSnapshot = await doc.ref
        .collection('expense_participants')
        .get();
      for (const pDoc of participantsSnapshot.docs) {
        await pDoc.ref.delete();
      }
      // Delete expense
      await doc.ref.delete();
      deletedCount++;
    }
    console.log(`   ✓ Deleted ${deletedCount} old expenses\n`);

    // Step 2: Delete all invites for this household
    console.log('🗑️  [DELETE] Removing existing invites...');
    const invitesSnapshot = await db.collection('invites').get();
    let deletedInvites = 0;
    for (const doc of invitesSnapshot.docs) {
      const data = doc.data();
      // Only delete if from our demo users
      if (data.senderEmail && data.senderEmail.includes('@example.com')) {
        await doc.ref.delete();
        deletedInvites++;
      }
    }
    console.log(`   ✓ Deleted ${deletedInvites} old invites\n`);

    // Step 3: Reseed fresh demo data
    console.log('💰 [CREATE] Adding fresh sample expenses...');
    const userIds = [JOHN_UID, '88lsOl4IrRVPv6kNrIggxTBpkMY2', 'f0flsqJYrhQJnoehBMKVwsLA5LW2'];
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

    let createdCount = 0;
    for (const expense of expenses) {
      const expenseRef = db.collection('expenses').doc();
      await expenseRef.set({
        id: expenseRef.id,
        householdId: HOUSEHOLD_ID,
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

      for (const participantId of userIds) {
        const participantName = [
          'John Doe',
          'Sarah Smith',
          'Mike Johnson',
        ][userIds.indexOf(participantId)];
        const splitAmount = Math.floor(expense.amountCents / userIds.length);
        
        await expenseRef.collection('expense_participants').add({
          userId: participantId,
          fullName: participantName,
          exactCents: splitAmount,
          percentageBps: null,
          shares: null,
        });
      }
      console.log(`   ✓ [CREATE] ${expense.title} (₱${(expense.amountCents / 100).toFixed(2)})`);
      createdCount++;
    }
    console.log();

    // Step 4: Create fresh invites
    console.log('📬 [CREATE] Adding fresh sample invites...');
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

    console.log('   ✓ [CREATE] Pending invite');
    console.log('   ✓ [CREATE] Accepted invite');
    console.log('   ✓ [CREATE] Rejected invite');
    console.log();

    // Step 5: Verify fresh data
    console.log('📖 [READ] Verifying clean data...');
    const freshExpenses = await db.collection('expenses')
      .where('householdId', '==', HOUSEHOLD_ID)
      .get();
    
    const freshInvites = await db.collection('invites').get();
    let myInvites = 0;
    for (const doc of freshInvites.docs) {
      const data = doc.data();
      if (data.senderEmail && data.senderEmail.includes('@example.com')) {
        myInvites++;
      }
    }

    console.log(`   ✓ ${freshExpenses.size} fresh expenses in database`);
    console.log(`   ✓ ${myInvites} fresh invites in database\n`);

    console.log('═══════════════════════════════════════════════════════════════════════════════════');
    console.log('✅ CLEAN AND RESEED COMPLETE!');
    console.log('═══════════════════════════════════════════════════════════════════════════════════\n');

    console.log('📊 Summary:');
    console.log(`   ✓ Deleted ${deletedCount} old expenses`);
    console.log(`   ✓ Deleted ${deletedInvites} old invites`);
    console.log(`   ✓ Created ${createdCount} fresh expenses`);
    console.log(`   ✓ Created 3 fresh invites\n`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error during clean and reseed:', error);
    process.exit(1);
  }
}

cleanAndReseed();
