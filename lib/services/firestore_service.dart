import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';
import '../models/expense_participant_model.dart';
import '../models/room_model.dart';
import '../models/roommate_model.dart';
import '../models/user_profile_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usersRef => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _householdsRef => _firestore.collection('households');
  CollectionReference<Map<String, dynamic>> get _membersRef => _firestore.collection('household_members');
  CollectionReference<Map<String, dynamic>> get _expensesRef => _firestore.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _invitesRef => _firestore.collection('invites');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'User is not authenticated.',
      );
    }
    return uid;
  }

  String _requireEmail() {
    final email = _auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Current account has no email.',
      );
    }
    return email;
  }

  DocumentReference<Map<String, dynamic>> userDoc(String uid) => _usersRef.doc(uid);

  Future<void> createUserProfileAfterSignUp({
    required String fullName,
    required String phoneNumber,
  }) async {
    final uid = _requireUid();
    final email = _requireEmail();
    final householdId = 'household_$uid';
    final now = FieldValue.serverTimestamp();

    await _householdsRef.doc(householdId).set({
      'id': householdId,
      'name': '$fullName Household',
      'ownerUid': uid,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _membersRef.doc('${householdId}_$uid').set({
      'householdId': householdId,
      'userId': uid,
      'fullName': fullName.trim(),
      'email': email,
      'role': 'owner',
      'status': 'active',
      'joinedAt': now,
    }, SetOptions(merge: true));

    await _usersRef.doc(uid).set({
      'id': uid,
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'email': email,
      'householdId': householdId,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Stream<UserProfileModel?> watchCurrentUserProfile() {
    final uid = _requireUid();
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return UserProfileModel.fromMap(data);
    });
  }

  Future<UserProfileModel?> getCurrentUserProfileModel() async {
    final uid = _requireUid();
    final snapshot = await _usersRef.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfileModel.fromMap(snapshot.data()!);
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final uid = _requireUid();
    final email = _requireEmail();
    await _usersRef.doc(uid).set({
      'id': uid,
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> getCurrentHouseholdId() async {
    final uid = _requireUid();
    final profile = await getCurrentUserProfileModel();
    final householdId = profile?.householdId.trim() ?? '';
    if (householdId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'No household found for current user.',
      );
    }

    final membershipDoc = await _membersRef.doc('${householdId}_$uid').get();
    final membershipData = membershipDoc.data();
    final isActive = (membershipData?['status'] as String? ?? '').trim().toLowerCase() == 'active';
    if (!membershipDoc.exists || !isActive) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'No active household membership found for current user.',
      );
    }

    return householdId;
  }

  Future<List<RoomModel>> getMyRooms() async {
    final uid = _requireUid();
    final memberships = await _membersRef
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .get();

    final rooms = <RoomModel>[];
    for (final member in memberships.docs) {
      final householdId = (member.data()['householdId'] as String? ?? '').trim();
      if (householdId.isEmpty) {
        continue;
      }
      final roomDoc = await _householdsRef.doc(householdId).get();
      final roomData = roomDoc.data();
      if (roomData == null) {
        continue;
      }
      rooms.add(RoomModel.fromMap(roomDoc.id, roomData));
    }
    rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rooms;
  }

  Future<RoomModel?> getCurrentRoom() async {
    final householdId = await getCurrentHouseholdId();
    final doc = await _householdsRef.doc(householdId).get();
    final data = doc.data();
    if (data == null) {
      return null;
    }
    return RoomModel.fromMap(doc.id, data);
  }

  Future<void> createRoom(String roomName) async {
    final uid = _requireUid();
    final email = _requireEmail();
    final profile = await getCurrentUserProfileModel();
    final trimmedName = roomName.trim();
    if (trimmedName.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Room name is required.',
      );
    }

    final roomRef = _householdsRef.doc();
    final now = FieldValue.serverTimestamp();
    await roomRef.set({
      'id': roomRef.id,
      'name': trimmedName,
      'ownerUid': uid,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _membersRef.doc('${roomRef.id}_$uid').set({
      'householdId': roomRef.id,
      'userId': uid,
      'fullName': profile?.fullName ?? _auth.currentUser?.displayName ?? email,
      'email': email,
      'role': 'owner',
      'status': 'active',
      'joinedAt': now,
    }, SetOptions(merge: true));

    await _usersRef.doc(uid).set({
      'householdId': roomRef.id,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> joinRoomById(String roomId) async {
    final uid = _requireUid();
    final email = _requireEmail();
    final profile = await getCurrentUserProfileModel();
    final targetRoomId = roomId.trim();
    if (targetRoomId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Room ID is required.',
      );
    }

    final roomDoc = await _householdsRef.doc(targetRoomId).get();
    if (!roomDoc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Room not found.',
      );
    }

    await _membersRef.doc('${targetRoomId}_$uid').set({
      'householdId': targetRoomId,
      'userId': uid,
      'fullName': profile?.fullName ?? _auth.currentUser?.displayName ?? email,
      'email': email,
      'role': 'member',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await switchActiveRoom(targetRoomId);
  }

  Future<void> switchActiveRoom(String roomId) async {
    final uid = _requireUid();
    final targetRoomId = roomId.trim();
    if (targetRoomId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Room ID is required.',
      );
    }
    await _usersRef.doc(uid).set({
      'householdId': targetRoomId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> leaveRoom(String roomId) async {
    final uid = _requireUid();
    final targetRoomId = roomId.trim();
    if (targetRoomId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Room ID is required.',
      );
    }
    await _membersRef.doc('${targetRoomId}_$uid').delete();

    final profile = await getCurrentUserProfileModel();
    if (profile?.householdId == targetRoomId) {
      final rooms = await getMyRooms();
      if (rooms.isNotEmpty) {
        await switchActiveRoom(rooms.first.id);
      } else {
        await _usersRef.doc(uid).set({
          'householdId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Stream<List<RoommateModel>> getRoommatesStream(String uid) {
    final stream = Stream.fromFuture(getCurrentHouseholdId()).asyncExpand((householdId) {
      return _membersRef
          .where('householdId', isEqualTo: householdId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
        final items = snapshot.docs
            .map((doc) => doc.data())
            .where((data) => (data['userId'] as String? ?? '').trim().isNotEmpty)
            .where((data) => (data['userId'] as String).trim() != uid)
            .map((data) {
          final linkedUid = (data['userId'] as String).trim();
          final displayName = (data['fullName'] as String? ?? '').trim();
          final email = (data['email'] as String? ?? '').trim();
          return RoommateModel(
            id: linkedUid,
            email: email,
            displayName: displayName.isEmpty ? email : displayName,
            linkedUid: linkedUid,
          );
        }).toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        return items;
      });
    });
    return stream.asBroadcastStream();
  }

  Future<List<RoommateModel>> getCurrentUserRoommates() async {
    final uid = _requireUid();
    final householdId = await getCurrentHouseholdId();
    final snapshot = await _membersRef
        .where('householdId', isEqualTo: householdId)
        .where('status', isEqualTo: 'active')
        .get();
    final roommates = snapshot.docs
        .map((doc) => doc.data())
        .where((data) => (data['userId'] as String? ?? '').trim().isNotEmpty)
        .where((data) => (data['userId'] as String).trim() != uid)
        .map((data) {
          final linkedUid = (data['userId'] as String).trim();
          final displayName = (data['fullName'] as String? ?? '').trim();
          final email = (data['email'] as String? ?? '').trim();
          return RoommateModel(
            id: linkedUid,
            email: email,
            displayName: displayName.isEmpty ? email : displayName,
            linkedUid: linkedUid,
          );
        })
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return roommates;
  }

  Stream<List<ExpenseModel>> getExpensesStream(String uid) {
    // Kept method signature for compatibility.
    final stream = Stream.fromFuture(getCurrentHouseholdId()).asyncExpand((householdId) {
      return _expensesRef
          .where('householdId', isEqualTo: householdId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
            .toList();
      });
    });
    return stream.asBroadcastStream();
  }

  Stream<List<ExpenseParticipantModel>> getExpenseParticipantsStream(String expenseId) {
    return _expensesRef
        .doc(expenseId)
        .collection('expense_participants')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseParticipantModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<ExpenseParticipantModel>> getExpenseParticipants(String expenseId) async {
    final snapshot = await _expensesRef.doc(expenseId).collection('expense_participants').get();
    return snapshot.docs
        .map((doc) => ExpenseParticipantModel.fromMap(doc.data()))
        .toList();
  }

  Future<Map<String, List<ExpenseParticipantModel>>> getParticipantsMapForExpenses(
    List<ExpenseModel> expenses,
  ) async {
    final result = <String, List<ExpenseParticipantModel>>{};
    for (final expense in expenses) {
      result[expense.id] = await getExpenseParticipants(expense.id);
    }
    return result;
  }

  Future<void> upsertExpense({
    required ExpenseModel expense,
    required List<ExpenseParticipantModel> participants,
  }) async {
    final uid = _requireUid();
    final householdId = await getCurrentHouseholdId();
    final ref = expense.id.isEmpty ? _expensesRef.doc() : _expensesRef.doc(expense.id);

    final payload = expense
        .copyWith(
          id: ref.id,
          createdByUserId: uid,
          householdId: householdId,
        )
        .toMap();
    payload['createdAt'] = expense.id.isEmpty
        ? FieldValue.serverTimestamp()
        : payload['createdAt'];

    await ref.set(payload, SetOptions(merge: true));

    final participantsRef = ref.collection('expense_participants');
    final existing = await participantsRef.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
    for (final participant in participants) {
      await participantsRef.add(participant.toMap());
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await upsertExpense(expense: expense, participants: const []);
  }

  Future<void> updateExpense(String expenseId, Map<String, dynamic> updatedData) async {
    await _expensesRef.doc(expenseId).update({
      ...updatedData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    final expenseRef = _expensesRef.doc(expenseId);
    final participants = await expenseRef.collection('expense_participants').get();
    for (final doc in participants.docs) {
      await doc.reference.delete();
    }
    await expenseRef.delete();
  }

  Future<List<ExpenseModel>> getCurrentUserExpenses() async {
    final householdId = await getCurrentHouseholdId();
    final snapshot = await _expensesRef
        .where('householdId', isEqualTo: householdId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final profile = await getCurrentUserProfileModel();
    return profile?.toMap();
  }

  Future<void> upsertCurrentUserProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    await updateCurrentUserProfile(
      fullName: displayName,
      phoneNumber: phoneNumber ?? '',
    );
  }

  Future<List<Map<String, dynamic>>> getAcceptedInvitesForCurrentUser() async {
    final uid = _requireUid();
    final snapshot = await _invitesRef
        .where('status', isEqualTo: 'accepted')
        .where('recipientUid', isEqualTo: uid)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<RoommateModel>> getRoomMembers(String roomId) async {
    final roomIdTrim = roomId.trim();
    if (roomIdTrim.isEmpty) {
      return [];
    }
    final snapshot = await _membersRef
        .where('householdId', isEqualTo: roomIdTrim)
        .where('status', isEqualTo: 'active')
        .get();
    final members = snapshot.docs
        .map((doc) => doc.data())
        .where((data) => (data['userId'] as String? ?? '').trim().isNotEmpty)
        .map((data) {
          final linkedUid = (data['userId'] as String).trim();
          final displayName = (data['fullName'] as String? ?? '').trim();
          final email = (data['email'] as String? ?? '').trim();
          return RoommateModel(
            id: linkedUid,
            email: email,
            displayName: displayName.isEmpty ? email : displayName,
            linkedUid: linkedUid,
          );
        })
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return members;
  }
}
