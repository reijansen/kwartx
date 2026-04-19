import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';
import '../models/roommate_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _expensesRef(String uid) {
    return _userDoc(uid).collection('expenses');
  }

  CollectionReference<Map<String, dynamic>> _roommatesRef(String uid) {
    return _userDoc(uid).collection('roommates');
  }

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

  Future<void> addExpense(ExpenseModel expense) async {
    final uid = _requireUid();
    await _expensesRef(uid).add(expense.toMap());
  }

  Stream<List<ExpenseModel>> getExpensesStream(String uid) {
    return _expensesRef(
      uid,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> updatedData,
  ) async {
    final uid = _requireUid();
    await _expensesRef(uid).doc(expenseId).update(updatedData);
  }

  Future<void> deleteExpense(String expenseId) async {
    final uid = _requireUid();
    await _expensesRef(uid).doc(expenseId).delete();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _requireUid();
    final snapshot = await _userDoc(uid).get();
    return snapshot.data();
  }

  Future<void> upsertCurrentUserProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    final uid = _requireUid();
    final user = _auth.currentUser;

    await _userDoc(uid).set({
      'displayName': displayName.trim(),
      'phoneNumber': (phoneNumber ?? '').trim(),
      'email': user?.email?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<RoommateModel>> getRoommatesStream(String uid) {
    return _roommatesRef(uid).snapshots().map((snapshot) {
      final roommates = snapshot.docs
          .map((doc) => RoommateModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      return roommates;
    });
  }

  Future<List<RoommateModel>> getCurrentUserRoommates() async {
    final uid = _requireUid();
    final snapshot = await _roommatesRef(uid).get();
    final roommates = snapshot.docs
        .map((doc) => RoommateModel.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return roommates;
  }

  Future<List<ExpenseModel>> getCurrentUserExpenses() async {
    final uid = _requireUid();
    final snapshot = await _expensesRef(uid).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
