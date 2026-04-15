import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitCount,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final int splitCount;
  final String category;
  final DateTime createdAt;

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? paidBy,
    int? splitCount,
    String? category,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splitCount: splitCount ?? this.splitCount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'splitCount': splitCount,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    }

    return ExpenseModel(
      id: id,
      title: (map['title'] ?? '') as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paidBy: (map['paidBy'] ?? '') as String,
      splitCount: (map['splitCount'] as num?)?.toInt() ?? 1,
      category: (map['category'] ?? 'General') as String,
      createdAt: createdAt,
    );
  }
}
