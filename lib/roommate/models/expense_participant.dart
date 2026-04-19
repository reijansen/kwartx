class ExpenseParticipant {
  const ExpenseParticipant({
    required this.userId,
    this.exactAmountCents,
    this.percentageBasisPoints,
    this.shares,
  });

  final String userId;
  final int? exactAmountCents;
  final int? percentageBasisPoints;
  final int? shares;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'exactAmountCents': exactAmountCents,
      'percentageBasisPoints': percentageBasisPoints,
      'shares': shares,
    };
  }

  factory ExpenseParticipant.fromJson(Map<String, dynamic> json) {
    return ExpenseParticipant(
      userId: (json['userId'] as String? ?? '').trim(),
      exactAmountCents: (json['exactAmountCents'] as num?)?.toInt(),
      percentageBasisPoints: (json['percentageBasisPoints'] as num?)?.toInt(),
      shares: (json['shares'] as num?)?.toInt(),
    );
  }
}
