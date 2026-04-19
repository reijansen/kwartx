class ExpenseValidationException implements Exception {
  const ExpenseValidationException(this.message);

  final String message;

  @override
  String toString() => 'ExpenseValidationException: $message';
}
