import '../models/expense.dart';

abstract class ExpenseRepository {
  Stream<List<RoommateExpense>> watchExpenses(String householdId);

  Future<void> upsertExpense(RoommateExpense expense);

  Future<void> deleteExpense({
    required String householdId,
    required String expenseId,
  });
}
