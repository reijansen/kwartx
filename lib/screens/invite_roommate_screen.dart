import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invite_model.dart';
import '../services/invite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dark_card.dart';
import '../widgets/primary_button.dart';

class InviteRoommateScreen extends StatefulWidget {
  const InviteRoommateScreen({super.key});

  @override
  State<InviteRoommateScreen> createState() => _InviteRoommateScreenState();
}

class _InviteRoommateScreenState extends State<InviteRoommateScreen> {
  final InviteService _inviteService = InviteService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMM d, y - h:mm a');
  bool _isSending = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String? get _currentEmail => _currentUser?.email?.trim();
  String? get _currentUid => _currentUser?.uid;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (_isSending) {
      return;
    }
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_currentEmail == null || _currentEmail!.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Your account has no email. Please re-sign in.',
        type: AppFeedbackType.error,
      );
      return;
    }

    final recipient = _emailController.text.trim();
    if (_inviteService.normalizeEmail(recipient) ==
        _inviteService.normalizeEmail(_currentEmail!)) {
      showAppSnackBar(
        context,
        message: 'You cannot invite your own email.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _inviteService.sendInvite(
        recipientEmail: recipient,
        message: _messageController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _emailController.clear();
      _messageController.clear();
      showAppSnackBar(
        context,
        message: 'Roommate invite sent.',
        type: AppFeedbackType.success,
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: error.message ?? 'Could not send invite.',
        type: AppFeedbackType.error,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Something went wrong while sending invite.',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _cancelInvite(String inviteId) async {
    try {
      await _inviteService.cancelInvite(inviteId);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Invite cancelled.',
        type: AppFeedbackType.info,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Could not cancel invite.',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _acceptInvite(String inviteId) async {
    try {
      await _inviteService.acceptInvite(inviteId);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Invite accepted.',
        type: AppFeedbackType.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Could not accept invite.',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _rejectInvite(String inviteId) async {
    try {
      await _inviteService.rejectInvite(inviteId);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Invite rejected.',
        type: AppFeedbackType.info,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Could not reject invite.',
        type: AppFeedbackType.error,
      );
    }
  }

  String _statusLabel(InviteStatus status) {
    switch (status) {
      case InviteStatus.accepted:
        return 'Accepted';
      case InviteStatus.rejected:
        return 'Rejected';
      case InviteStatus.cancelled:
        return 'Cancelled';
      case InviteStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(InviteStatus status) {
    switch (status) {
      case InviteStatus.accepted:
        return AppTheme.successGreen;
      case InviteStatus.rejected:
      case InviteStatus.cancelled:
        return AppTheme.dangerRed;
      case InviteStatus.pending:
        return AppTheme.secondaryAccentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;
    final email = _currentEmail;

    if (uid == null || uid.isEmpty || email == null || email.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roommate Invites')),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
          child: const Center(
            child: AppEmptyState(
              title: 'Account email unavailable',
              subtitle: 'Please sign in again to manage invites.',
              icon: Icons.mark_email_unread_outlined,
            ),
          ),
        ),
      );
    }

    final normalizedEmail = _inviteService.normalizeEmail(email);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Roommate Invites'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sent'),
              Tab(text: 'Received'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: DarkCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Invite by email',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'Roommate Email',
                          hintText: 'roommate@example.com',
                          prefixIcon: Icons.alternate_email_rounded,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSending,
                          validator: (value) {
                            final emailValue = (value ?? '').trim();
                            if (emailValue.isEmpty) {
                              return 'Email is required.';
                            }
                            final valid = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(emailValue);
                            if (!valid) {
                              return 'Please enter a valid email.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Message (Optional)',
                          hintText: 'Short note for your roommate',
                          prefixIcon: Icons.message_outlined,
                          controller: _messageController,
                          enabled: !_isSending,
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _sendInvite(),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Send Invite',
                          isLoading: _isSending,
                          onPressed: _sendInvite,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    StreamBuilder<List<InviteModel>>(
                      stream: _inviteService.getSentInvitesStream(uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: AppLoadingIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: AppEmptyState(
                              title: 'Could not load sent invites',
                              subtitle: 'Please try again in a moment.',
                              icon: Icons.error_outline_rounded,
                            ),
                          );
                        }

                        final invites = snapshot.data ?? <InviteModel>[];
                        if (invites.isEmpty) {
                          return const Center(
                            child: AppEmptyState(
                              title: 'No sent invites yet',
                              subtitle: 'Invite a roommate using email above.',
                              icon: Icons.mail_outline_rounded,
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: invites.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final invite = invites[index];
                            return DarkCard(
                              radius: 14,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invite.recipientEmail,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sent ${_dateFormatter.format(invite.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.mutedText),
                                  ),
                                  if ((invite.message ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      invite.message!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          color: _statusColor(
                                            invite.status,
                                          ).withAlpha(40),
                                          border: Border.all(
                                            color: _statusColor(invite.status),
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(invite.status),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: _statusColor(
                                                  invite.status,
                                                ),
                                              ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (invite.isPending)
                                        TextButton(
                                          onPressed: () =>
                                              _cancelInvite(invite.id),
                                          child: const Text('Cancel'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    StreamBuilder<List<InviteModel>>(
                      stream: _inviteService.getReceivedInvitesStream(
                        normalizedEmail,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: AppLoadingIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: AppEmptyState(
                              title: 'Could not load received invites',
                              subtitle: 'Please try again in a moment.',
                              icon: Icons.error_outline_rounded,
                            ),
                          );
                        }

                        final invites = snapshot.data ?? <InviteModel>[];
                        if (invites.isEmpty) {
                          return const Center(
                            child: AppEmptyState(
                              title: 'No invites received',
                              subtitle:
                                  'Invites sent to your email will appear here.',
                              icon: Icons.mark_email_unread_outlined,
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: invites.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final invite = invites[index];
                            return DarkCard(
                              radius: 14,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invite.senderEmail,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Received ${_dateFormatter.format(invite.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.mutedText),
                                  ),
                                  if ((invite.message ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      invite.message!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          color: _statusColor(
                                            invite.status,
                                          ).withAlpha(40),
                                          border: Border.all(
                                            color: _statusColor(invite.status),
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(invite.status),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: _statusColor(
                                                  invite.status,
                                                ),
                                              ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (invite.isPending) ...[
                                        TextButton(
                                          onPressed: () =>
                                              _rejectInvite(invite.id),
                                          child: const Text('Reject'),
                                        ),
                                        const SizedBox(width: 4),
                                        FilledButton(
                                          onPressed: () =>
                                              _acceptInvite(invite.id),
                                          child: const Text('Accept'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
