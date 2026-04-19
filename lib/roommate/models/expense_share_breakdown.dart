class ExpenseShareBreakdown {
  const ExpenseShareBreakdown({
    required this.expenseId,
    required this.totalAmountCents,
    required this.paidByUserId,
    required this.sharesByUserId,
    required this.payerAdvancedCents,
  });

  final String expenseId;
  final int totalAmountCents;
  final String paidByUserId;
  final Map<String, int> sharesByUserId;
  final int payerAdvancedCents;

  Map<String, dynamic> toJson() {
    return {
      'expenseId': expenseId,
      'totalAmountCents': totalAmountCents,
      'paidByUserId': paidByUserId,
      'sharesByUserId': sharesByUserId,
      'payerAdvancedCents': payerAdvancedCents,
    };
  }
}
