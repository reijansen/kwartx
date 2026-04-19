import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.householdId,
    required this.title,
    required this.amountCents,
    required this.paidByUserId,
    required this.paidByName,
    required this.createdByUserId,
    required this.date,
    required this.category,
    required this.splitType,
    required this.participantUserIds,
    this.notes,
    this.splitConfig = const {},
  });

  final String id;
  final String householdId;
  final String title;
  final int amountCents;
  final String paidByUserId;
  final String paidByName;
  final String createdByUserId;
  final DateTime date;
  final String category;
  final String splitType;
  final List<String> participantUserIds;
  final String? notes;
  final Map<String, dynamic> splitConfig;

  double get amount => amountCents / 100.0;

  ExpenseModel copyWith({
    String? id,
    String? householdId,
    String? title,
    int? amountCents,
    String? paidByUserId,
    String? paidByName,
    String? createdByUserId,
    DateTime? date,
    String? category,
    String? splitType,
    List<String>? participantUserIds,
    String? notes,
    Map<String, dynamic>? splitConfig,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidByName: paidByName ?? this.paidByName,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      date: date ?? this.date,
      category: category ?? this.category,
      splitType: splitType ?? this.splitType,
      participantUserIds: participantUserIds ?? this.participantUserIds,
      notes: notes ?? this.notes,
      splitConfig: splitConfig ?? this.splitConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'householdId': householdId,
      'title': title,
      'amountCents': amountCents,
      'paidByUserId': paidByUserId,
      'paidByName': paidByName,
      'createdByUserId': createdByUserId,
      'date': Timestamp.fromDate(date),
      'category': category,
      'splitType': splitType,
      'participantUserIds': participantUserIds,
      'notes': notes,
      'splitConfig': splitConfig,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = _readDateTime(map['date']) ?? DateTime.now();
    final legacyAmount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final amountCentsFromMap = (map['amountCents'] as num?)?.toInt();
    final amountCents = amountCentsFromMap ?? (legacyAmount * 100).round();
    final participantIds =
        (map['participantUserIds'] as List<dynamic>? ?? const [])
            .map((it) => (it as String).trim())
            .where((it) => it.isNotEmpty)
            .toList();

    return ExpenseModel(
      id: id,
      householdId: _readString(map['householdId'], fallback: ''),
      title: _readString(map['title'], fallback: 'Untitled expense'),
      amountCents: amountCents <= 0 ? 0 : amountCents,
      paidByUserId: _readString(map['paidByUserId'], fallback: ''),
      paidByName: _readString(
        map['paidByName'],
        fallback: _readString(map['paidBy'], fallback: 'Unknown payer'),
      ),
      createdByUserId: _readString(map['createdByUserId'], fallback: ''),
      date: createdAt,
      category: _readString(map['category'], fallback: 'misc'),
      splitType: _readString(map['splitType'], fallback: 'equal'),
      participantUserIds: participantIds,
      notes: (map['notes'] as String?)?.trim(),
      splitConfig: (map['splitConfig'] as Map<String, dynamic>?) ?? const {},
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
