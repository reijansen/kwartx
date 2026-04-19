class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.displayName,
    required this.email,
    this.isCurrentUser = false,
  });

  final String id;
  final String displayName;
  final String email;
  final bool isCurrentUser;

  HouseholdMember copyWith({
    String? id,
    String? displayName,
    String? email,
    bool? isCurrentUser,
  }) {
    return HouseholdMember(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'isCurrentUser': isCurrentUser,
    };
  }

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: (json['id'] as String? ?? '').trim(),
      displayName: (json['displayName'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}
