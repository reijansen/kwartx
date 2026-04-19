import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';
import '../models/invite_model.dart';

class InviteService {
  InviteService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _invitesRef =>
      _firestore.collection('invites');

  CollectionReference<Map<String, dynamic>> get _mailRef =>
      _firestore.collection('mail');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'User is not authenticated.',
      );
    }
    return uid;
  }

  String _requireEmail() {
    final email = _auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Current account has no email.',
      );
    }
    return email;
  }

  String normalizeEmail(String email) => email.trim().toLowerCase();

  Future<void> sendInvite({
    required String recipientEmail,
    String? message,
  }) async {
    final senderUid = _requireUid();
    final senderEmail = _requireEmail();
    final senderProfile = await _firestore.collection('users').doc(senderUid).get();
    final senderFullName = (senderProfile.data()?['fullName'] as String?)?.trim();
    final recipientNormalized = normalizeEmail(recipientEmail);
    final senderNormalized = normalizeEmail(senderEmail);

    if (recipientNormalized == senderNormalized) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'You cannot invite your own email.',
      );
    }

    final existing = await _invitesRef
        .where('senderUid', isEqualTo: senderUid)
        .where('recipientEmailNormalized', isEqualTo: recipientNormalized)
        .get();

    final hasPending = existing.docs.any(
      (doc) =>
          (doc.data()['status'] as String? ?? '').trim().toLowerCase() ==
          'pending',
    );
    if (hasPending) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'A pending invite already exists for this email.',
      );
    }

    final cleanedMessage = (message ?? '').trim();

    final inviteDoc = await _invitesRef.add({
      'senderUid': senderUid,
      'senderEmail': senderEmail,
      'senderDisplayName': senderFullName ?? _auth.currentUser?.displayName?.trim(),
      'recipientEmail': recipientEmail.trim(),
      'recipientEmailNormalized': recipientNormalized,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'message': cleanedMessage.isEmpty ? null : cleanedMessage,
    });

    await _mailRef.add({
      'to': recipientEmail.trim(),
      'message': {
        'subject': 'You were invited to join KwartX',
        'text':
            '${senderEmail.trim()} invited you to join KwartX as a roommate.\n\n'
            '${cleanedMessage.isEmpty ? '' : 'Message: $cleanedMessage\n\n'}'
            'Sign in using this email to review the invite.',
        'html':
            '<p><strong>${senderEmail.trim()}</strong> invited you to join <strong>KwartX</strong> as a roommate.</p>'
            '${cleanedMessage.isEmpty ? '' : '<p>Message: ${_escapeHtml(cleanedMessage)}</p>'}'
            '<p>Sign in using this email to review the invite.</p>',
      },
      'meta': {'inviteId': inviteDoc.id, 'app': 'KwartX'},
    });
  }

  Stream<List<InviteModel>> getSentInvitesStream(String senderUid) {
    return _invitesRef.where('senderUid', isEqualTo: senderUid).snapshots().map(
      (snapshot) {
        final invites =
            snapshot.docs
                .map((doc) => InviteModel.fromMap(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return invites;
      },
    );
  }

  Stream<List<InviteModel>> getReceivedInvitesStream(
    String recipientEmailNormalized,
  ) {
    return _invitesRef
        .where('recipientEmailNormalized', isEqualTo: recipientEmailNormalized)
        .snapshots()
        .map((snapshot) {
          final invites =
              snapshot.docs
                  .map((doc) => InviteModel.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invites;
        });
  }

  Future<void> acceptInvite(String inviteId) async {
    final uid = _requireUid();
    final email = _requireEmail();
    final normalized = normalizeEmail(email);
    final recipientProfile = await _firestore.collection('users').doc(uid).get();
    final recipientFullName = (recipientProfile.data()?['fullName'] as String?)?.trim();

    final docRef = _invitesRef.doc(inviteId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Invite not found.',
      );
    }

    final data = snapshot.data()!;
    final status = (data['status'] as String? ?? '').trim().toLowerCase();
    final recipientEmailNormalized =
        (data['recipientEmailNormalized'] as String? ?? '')
            .trim()
            .toLowerCase();
    if (status != 'pending') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Only pending invites can be accepted.',
      );
    }
    if (recipientEmailNormalized != normalized) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'This invite is not addressed to your account.',
      );
    }

    await docRef.update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'recipientUid': uid,
      'recipientDisplayName': recipientFullName,
    });

    final senderUid = (data['senderUid'] as String? ?? '').trim();
    final senderEmail = (data['senderEmail'] as String? ?? '').trim();
    final senderDisplayName = (data['senderDisplayName'] as String?)?.trim();
    final senderProfile = await _firestore.collection('users').doc(senderUid).get();
    final senderHouseholdId =
        (senderProfile.data()?['householdId'] as String? ?? '').trim();

    if (senderHouseholdId.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set({
        'householdId': senderHouseholdId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore
          .collection('household_members')
          .doc('${senderHouseholdId}_$uid')
          .set({
        'householdId': senderHouseholdId,
        'userId': uid,
        'fullName': recipientFullName,
        'email': email,
        'role': 'member',
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('roommates')
        .doc(senderUid.isEmpty ? normalizeEmail(senderEmail) : senderUid)
        .set({
          'email': senderEmail.isEmpty
              ? AppConstants.unknownPayer
              : senderEmail,
          'displayName': senderDisplayName,
          'linkedUid': senderUid.isEmpty ? null : senderUid,
          'addedAt': FieldValue.serverTimestamp(),
          'source': 'invite',
        }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(senderUid)
        .collection('roommates')
        .doc(uid)
        .set({
      'email': email,
      'displayName': recipientFullName ?? email,
      'linkedUid': uid,
      'addedAt': FieldValue.serverTimestamp(),
      'source': 'invite',
    }, SetOptions(merge: true));
  }

  Future<void> rejectInvite(String inviteId) async {
    await _setStatusForRecipient(inviteId, 'rejected');
  }

  Future<void> cancelInvite(String inviteId) async {
    final uid = _requireUid();
    final docRef = _invitesRef.doc(inviteId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Invite not found.',
      );
    }

    final data = snapshot.data()!;
    final senderUid = (data['senderUid'] as String? ?? '').trim();
    final status = (data['status'] as String? ?? '').trim().toLowerCase();
    if (senderUid != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Only the sender can cancel this invite.',
      );
    }
    if (status != 'pending') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Only pending invites can be cancelled.',
      );
    }

    await docRef.update({'status': 'cancelled'});
  }

  Future<void> _setStatusForRecipient(String inviteId, String status) async {
    final email = _requireEmail();
    final normalized = normalizeEmail(email);

    final docRef = _invitesRef.doc(inviteId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Invite not found.',
      );
    }

    final data = snapshot.data()!;
    final recipientEmailNormalized =
        (data['recipientEmailNormalized'] as String? ?? '')
            .trim()
            .toLowerCase();
    final currentStatus = (data['status'] as String? ?? '')
        .trim()
        .toLowerCase();

    if (currentStatus != 'pending') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Only pending invites can be updated.',
      );
    }
    if (recipientEmailNormalized != normalized) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'This invite is not addressed to your account.',
      );
    }

    await docRef.update({
      'status': status,
      if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
