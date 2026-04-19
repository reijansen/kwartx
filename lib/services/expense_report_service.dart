import '../models/expense_model.dart';
import '../constants/app_constants.dart';

enum ReportScope {
  allTime('All Time'),
  thisWeek('This Week'),
  thisMonth('This Month');

  const ReportScope(this.label);
  final String label;
}

class ExpenseReportData {
  const ExpenseReportData({
    required this.scope,
    required this.totalExpenses,
    required this.totalEntries,
    required this.thisMonthTotal,
    required this.averageExpense,
    required this.categoryTotals,
    required this.payerTotals,
  });

  final ReportScope scope;
  final double totalExpenses;
  final int totalEntries;
  final double thisMonthTotal;
  final double averageExpense;
  final List<MapEntry<String, double>> categoryTotals;
  final List<MapEntry<String, double>> payerTotals;
}

class ExpenseReportService {
  const ExpenseReportService._();

  static List<ExpenseModel> filterByScope(
    List<ExpenseModel> expenses, {
    required ReportScope scope,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();

    bool matches(ExpenseModel expense) {
      switch (scope) {
        case ReportScope.allTime:
          return true;
        case ReportScope.thisMonth:
          return expense.date.year == reference.year &&
              expense.date.month == reference.month;
        case ReportScope.thisWeek:
          final weekStart = _startOfWeek(reference);
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          return !expenseDate.isBefore(weekStart);
      }
    }

    return expenses.where(matches).toList();
  }

  static ExpenseReportData buildReport(
    List<ExpenseModel> allExpenses, {
    required ReportScope scope,
    DateTime? now,
  }) {
    final filtered = filterByScope(allExpenses, scope: scope, now: now);
    final monthOnly = filterByScope(
      allExpenses,
      scope: ReportScope.thisMonth,
      now: now,
    );

    final total = filtered.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final monthTotal = monthOnly.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final average = filtered.isEmpty ? 0.0 : total / filtered.length;

    final payerMap = <String, double>{};
    final categoryMap = <String, double>{};

    for (final expense in filtered) {
      final payer = _safeLabel(expense.paidByName, AppConstants.unknownPayer);
      final category = _safeLabel(
        expense.category,
        AppConstants.defaultCategory,
      );
      payerMap[payer] = (payerMap[payer] ?? 0) + expense.amount;
      categoryMap[category] = (categoryMap[category] ?? 0) + expense.amount;
    }

    final payerTotals = payerMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoryTotals = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ExpenseReportData(
      scope: scope,
      totalExpenses: total,
      totalEntries: filtered.length,
      thisMonthTotal: monthTotal,
      averageExpense: average,
      categoryTotals: categoryTotals,
      payerTotals: payerTotals,
    );
  }

  static String buildShareText(
    ExpenseReportData report, {
    required String Function(double value) formatCurrency,
  }) {
    final buffer = StringBuffer()
      ..writeln('KwartX Expense Report')
      ..writeln('Scope: ${report.scope.label}')
      ..writeln('Total Expenses: ${formatCurrency(report.totalExpenses)}')
      ..writeln('Total Entries: ${report.totalEntries}')
      ..writeln('This Month: ${formatCurrency(report.thisMonthTotal)}')
      ..writeln('Average Expense: ${formatCurrency(report.averageExpense)}')
      ..writeln()
      ..writeln('Category Breakdown:');

    if (report.categoryTotals.isEmpty) {
      buffer.writeln('- No category data');
    } else {
      for (final item in report.categoryTotals) {
        buffer.writeln('- ${item.key}: ${formatCurrency(item.value)}');
      }
    }

    buffer
      ..writeln()
      ..writeln('Paid By:');

    if (report.payerTotals.isEmpty) {
      buffer.writeln('- No payer data');
    } else {
      for (final item in report.payerTotals) {
        buffer.writeln('- ${item.key}: ${formatCurrency(item.value)}');
      }
    }

    return buffer.toString().trim();
  }

  static DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static String _safeLabel(String? raw, String fallback) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }
}
