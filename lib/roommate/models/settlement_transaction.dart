class SettlementTransaction {
  const SettlementTransaction({
    required this.fromUserId,
    required this.toUserId,
    required this.amountCents,
  });

  final String fromUserId;
  final String toUserId;
  final int amountCents;

  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amountCents': amountCents,
    };
  }
}
