import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.createdAt,
    required this.householdId,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final DateTime createdAt;
  final String householdId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'householdId': householdId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: (map['id'] as String? ?? '').trim(),
      fullName: (map['fullName'] as String? ?? '').trim(),
      phoneNumber: (map['phoneNumber'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      createdAt: _readDateTime(map['createdAt']) ?? DateTime.now(),
      householdId: (map['householdId'] as String? ?? '').trim(),
    );
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
