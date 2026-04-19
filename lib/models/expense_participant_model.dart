class ExpenseParticipantModel {
  const ExpenseParticipantModel({
    required this.userId,
    required this.fullName,
    this.exactCents,
    this.percentageBps,
    this.shares,
  });

  final String userId;
  final String fullName;
  final int? exactCents;
  final int? percentageBps;
  final int? shares;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'exactCents': exactCents,
      'percentageBps': percentageBps,
      'shares': shares,
    };
  }

  factory ExpenseParticipantModel.fromMap(Map<String, dynamic> map) {
    return ExpenseParticipantModel(
      userId: (map['userId'] as String? ?? '').trim(),
      fullName: (map['fullName'] as String? ?? '').trim(),
      exactCents: (map['exactCents'] as num?)?.toInt(),
      percentageBps: (map['percentageBps'] as num?)?.toInt(),
      shares: (map['shares'] as num?)?.toInt(),
    );
  }
}
