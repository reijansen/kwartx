class SettlementViewModel {
  const SettlementViewModel({
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.amountCents,
  });

  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final int amountCents;
}
