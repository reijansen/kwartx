class ExpenseReferenceData {
  ExpenseReferenceData._();

  static const List<String> categories = <String>[
    'General',
    'Food',
    'Transport',
    'Bills',
    'Rent',
    'Utilities',
    'Shopping',
    'Entertainment',
    'Travel',
    'Health',
    'Education',
    'Other',
  ];

  static const String defaultCategory = 'General';
  static const String unknownPayer = 'Unknown payer';
}
