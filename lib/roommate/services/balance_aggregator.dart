import '../models/balance_summary.dart';
import '../models/expense.dart';
import '../models/household_member.dart';
import 'expense_calculator.dart';

class BalanceAggregator {
  BalanceAggregator({ExpenseCalculator? calculator})
    : _calculator = calculator ?? const ExpenseCalculator();

  final ExpenseCalculator _calculator;

  List<BalanceSummary> aggregate({
    required List<HouseholdMember> members,
    required List<RoommateExpense> expenses,
  }) {
    final displayNameById = <String, String>{
      for (final member in members) member.id: member.displayName,
    };

    final paidById = <String, int>{};
    final owedById = <String, int>{};

    for (final expense in expenses) {
      final breakdown = _calculator.calculateBreakdown(expense);
      paidById[expense.paidByUserId] =
          (paidById[expense.paidByUserId] ?? 0) + expense.amountCents;

      breakdown.sharesByUserId.forEach((userId, owed) {
        owedById[userId] = (owedById[userId] ?? 0) + owed;
      });
    }

    final allUserIds = <String>{
      ...displayNameById.keys,
      ...paidById.keys,
      ...owedById.keys,
    };

    final result = allUserIds.map((userId) {
      return BalanceSummary(
        userId: userId,
        displayName: displayNameById[userId] ?? userId,
        totalPaidCents: paidById[userId] ?? 0,
        totalOwedCents: owedById[userId] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return result;
  }
}
