import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteStatus { pending, accepted, rejected, cancelled }

class InviteModel {
  const InviteModel({
    required this.id,
    required this.senderUid,
    required this.senderEmail,
    required this.recipientEmail,
    required this.recipientEmailNormalized,
    required this.status,
    required this.createdAt,
    this.senderDisplayName,
    this.recipientUid,
    this.recipientDisplayName,
    this.message,
    this.acceptedAt,
    this.rejectedAt,
  });

  final String id;
  final String senderUid;
  final String senderEmail;
  final String recipientEmail;
  final String recipientEmailNormalized;
  final InviteStatus status;
  final DateTime createdAt;
  final String? senderDisplayName;
  final String? recipientUid;
  final String? recipientDisplayName;
  final String? message;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;

  bool get isPending => status == InviteStatus.pending;

  factory InviteModel.fromMap(String id, Map<String, dynamic> map) {
    final statusRaw = (map['status'] as String? ?? 'pending').trim();
    final createdAt = _readDateTime(map['createdAt']) ?? DateTime.now();

    return InviteModel(
      id: id,
      senderUid: (map['senderUid'] as String? ?? '').trim(),
      senderEmail: (map['senderEmail'] as String? ?? '').trim(),
      recipientEmail: (map['recipientEmail'] as String? ?? '').trim(),
      recipientEmailNormalized:
          (map['recipientEmailNormalized'] as String? ?? '').trim(),
      status: _statusFromString(statusRaw),
      createdAt: createdAt,
      senderDisplayName: (map['senderDisplayName'] as String?)?.trim(),
      recipientUid: (map['recipientUid'] as String?)?.trim(),
      recipientDisplayName: (map['recipientDisplayName'] as String?)?.trim(),
      message: (map['message'] as String?)?.trim(),
      acceptedAt: _readDateTime(map['acceptedAt']),
      rejectedAt: _readDateTime(map['rejectedAt']),
    );
  }

  static InviteStatus _statusFromString(String value) {
    switch (value) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'rejected':
        return InviteStatus.rejected;
      case 'cancelled':
        return InviteStatus.cancelled;
      default:
        return InviteStatus.pending;
    }
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
