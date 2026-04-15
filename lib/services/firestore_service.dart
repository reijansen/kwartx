import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _expensesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('expenses');
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
}
