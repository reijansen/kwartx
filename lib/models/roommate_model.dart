import 'package:cloud_firestore/cloud_firestore.dart';

class RoommateModel {
  const RoommateModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.linkedUid,
  });

  final String id;
  final String email;
  final String displayName;
  final String? linkedUid;

  factory RoommateModel.fromMap(String id, Map<String, dynamic> map) {
    final email = (map['email'] as String? ?? '').trim();
    final displayName = (map['displayName'] as String?)?.trim();
    final linkedUid = (map['linkedUid'] as String?)?.trim();

    return RoommateModel(
      id: id,
      email: email,
      displayName:
          (displayName == null || displayName.isEmpty) ? email : displayName,
      linkedUid: linkedUid == null || linkedUid.isEmpty ? null : linkedUid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'linkedUid': linkedUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
