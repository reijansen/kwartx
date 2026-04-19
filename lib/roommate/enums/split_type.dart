enum SplitType { equal, exact, percentage, shares }

extension SplitTypeX on SplitType {
  String get value => switch (this) {
    SplitType.equal => 'equal',
    SplitType.exact => 'exact',
    SplitType.percentage => 'percentage',
    SplitType.shares => 'shares',
  };

  static SplitType fromValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'exact':
        return SplitType.exact;
      case 'percentage':
        return SplitType.percentage;
      case 'shares':
        return SplitType.shares;
      case 'equal':
      default:
        return SplitType.equal;
    }
  }
}
