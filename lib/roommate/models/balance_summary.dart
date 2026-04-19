class BalanceSummary {
  const BalanceSummary({
    required this.userId,
    required this.displayName,
    required this.totalPaidCents,
    required this.totalOwedCents,
  });

  final String userId;
  final String displayName;
  final int totalPaidCents;
  final int totalOwedCents;

  int get netBalanceCents => totalPaidCents - totalOwedCents;

  bool get isCreditor => netBalanceCents > 0;
  bool get isDebtor => netBalanceCents < 0;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'totalPaidCents': totalPaidCents,
      'totalOwedCents': totalOwedCents,
      'netBalanceCents': netBalanceCents,
    };
  }
}
