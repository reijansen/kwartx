import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

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
    final createdAt = _readDateTime(map['createdAt']) ?? DateTime.now();
    final splitCount = (map['splitCount'] as num?)?.toInt() ?? 1;
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;

    return ExpenseModel(
      id: id,
      title: _readString(map['title'], fallback: 'Untitled expense'),
      amount: amount.isNegative ? 0 : amount,
      paidBy: _readString(map['paidBy'], fallback: AppConstants.unknownPayer),
      splitCount: splitCount <= 0 ? 1 : splitCount,
      category: _readString(
        map['category'],
        fallback: AppConstants.defaultCategory,
      ),
      createdAt: createdAt,
    );
  }

  static String _readString(dynamic value, {required String fallback}) {
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return fallback;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
