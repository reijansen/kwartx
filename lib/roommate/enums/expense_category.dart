enum ExpenseCategory {
  rent,
  electricity,
  water,
  wifi,
  groceries,
  repairs,
  misc,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get value => switch (this) {
    ExpenseCategory.rent => 'rent',
    ExpenseCategory.electricity => 'electricity',
    ExpenseCategory.water => 'water',
    ExpenseCategory.wifi => 'wifi',
    ExpenseCategory.groceries => 'groceries',
    ExpenseCategory.repairs => 'repairs',
    ExpenseCategory.misc => 'misc',
  };

  static ExpenseCategory fromValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'rent':
        return ExpenseCategory.rent;
      case 'electricity':
        return ExpenseCategory.electricity;
      case 'water':
        return ExpenseCategory.water;
      case 'wifi':
        return ExpenseCategory.wifi;
      case 'groceries':
        return ExpenseCategory.groceries;
      case 'repairs':
        return ExpenseCategory.repairs;
      case 'misc':
      default:
        return ExpenseCategory.misc;
    }
  }
}
