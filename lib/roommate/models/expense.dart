import '../enums/expense_category.dart';
import '../enums/split_type.dart';
import 'expense_participant.dart';

class RoommateExpense {
  const RoommateExpense({
    required this.id,
    required this.householdId,
    required this.title,
    required this.amountCents,
    required this.paidByUserId,
    required this.createdByUserId,
    required this.date,
    required this.category,
    required this.splitType,
    required this.participants,
    this.notes,
  });

  final String id;
  final String householdId;
  final String title;
  final int amountCents;
  final String paidByUserId;
  final String createdByUserId;
  final DateTime date;
  final ExpenseCategory category;
  final SplitType splitType;
  final List<ExpenseParticipant> participants;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'householdId': householdId,
      'title': title,
      'amountCents': amountCents,
      'paidByUserId': paidByUserId,
      'createdByUserId': createdByUserId,
      'date': date.toIso8601String(),
      'category': category.value,
      'splitType': splitType.value,
      'participants': participants.map((it) => it.toJson()).toList(),
      'notes': notes,
    };
  }

  factory RoommateExpense.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>? ?? const [];
    return RoommateExpense(
      id: (json['id'] as String? ?? '').trim(),
      householdId: (json['householdId'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      paidByUserId: (json['paidByUserId'] as String? ?? '').trim(),
      createdByUserId: (json['createdByUserId'] as String? ?? '').trim(),
      date:
          DateTime.tryParse((json['date'] as String? ?? '').trim()) ??
          DateTime.now(),
      category: ExpenseCategoryX.fromValue(
        (json['category'] as String? ?? '').trim(),
      ),
      splitType: SplitTypeX.fromValue(
        (json['splitType'] as String? ?? '').trim(),
      ),
      participants: participantsJson
          .map((item) => ExpenseParticipant.fromJson(item as Map<String, dynamic>))
          .toList(),
      notes: (json['notes'] as String?)?.trim(),
    );
  }
}
