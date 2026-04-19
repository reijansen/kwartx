import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invite_model.dart';
import '../models/roommate_model.dart';
import '../services/firestore_service.dart';
import '../services/invite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/dark_card.dart';
import '../widgets/invite_form_sheet.dart';

class InviteRoommateScreen extends StatefulWidget {
  const InviteRoommateScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<InviteRoommateScreen> createState() => _InviteRoommateScreenState();
}

class _InviteRoommateScreenState extends State<InviteRoommateScreen> {
  final InviteService _inviteService = InviteService();
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormatter = DateFormat('MMM d, y - h:mm a');

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String? get _currentEmail => _currentUser?.email?.trim();
  String? get _currentUid => _currentUser?.uid;

  Future<void> _sendInvite({
    required String recipientEmail,
    String? message,
  }) async {
    await _inviteService.sendInvite(
      recipientEmail: recipientEmail,
      message: message,
    );
  }

  Future<void> _openInviteSheet() async {
    final email = _currentEmail;
    if (email == null || email.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Your account email is unavailable. Please sign in again.',
        type: AppFeedbackType.error,
      );
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return InviteFormSheet(
          currentUserEmail: email,
          onSendInvite: _sendInvite,
        );
      },
    );
    if (!mounted || result != true) {
      return;
    }
    showAppSnackBar(
      context,
      message: 'Invite sent successfully.',
      type: AppFeedbackType.success,
    );
  }

  Future<void> _cancelInvite(String inviteId) async {
    await _inviteService.cancelInvite(inviteId);
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: 'Invite cancelled.',
      type: AppFeedbackType.info,
    );
  }

  Future<void> _acceptInvite(String inviteId) async {
    await _inviteService.acceptInvite(inviteId);
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: 'Invite accepted. Roommate added.',
      type: AppFeedbackType.success,
    );
  }

  Future<void> _rejectInvite(String inviteId) async {
    await _inviteService.rejectInvite(inviteId);
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: 'Invite declined.',
      type: AppFeedbackType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;
    final email = _currentEmail;
    if (uid == null || uid.isEmpty || email == null || email.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in again to manage invites.'),
        ),
      );
    }

    return DefaultTabController(
      initialIndex: widget.initialTabIndex.clamp(0, 2),
      length: 3,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Roommates',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              'Manage invites and accepted members',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withAlpha(220),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _openInviteSheet,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Invite'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryAccentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF4EC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2E6DA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const TabBar(
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              labelColor: AppTheme.textPrimary,
                              unselectedLabelColor: AppTheme.mutedText,
                              tabs: [
                                Tab(text: 'Sent'),
                                Tab(text: 'Received'),
                                Tab(text: 'Roommates'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildSentTab(uid),
                              _buildReceivedTab(email),
                              _buildRoommatesTab(uid),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSentTab(String uid) {
    return StreamBuilder<List<InviteModel>>(
      stream: _inviteService.getSentInvitesStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }
        if (snapshot.hasError) {
          return _SimpleInviteState(
            title: 'Unable to load sent invites',
            subtitle: mapAppErrorMessage(snapshot.error!),
            icon: Icons.cloud_off_rounded,
            onAction: () => setState(() {}),
            actionLabel: 'Retry',
          );
        }
        final invites = snapshot.data ?? const <InviteModel>[];
        if (invites.isEmpty) {
          return const _SimpleInviteState(
            title: 'No sent invites yet',
            subtitle: 'Invite roommates to start splitting household expenses.',
            icon: Icons.mail_outline_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final invite = invites[index];
            return InviteTile(
              title: invite.recipientDisplayName ?? invite.recipientEmail,
              subtitle: 'Sent ${_dateFormatter.format(invite.createdAt)}',
              status: _statusLabel(invite.status),
              trailing: invite.isPending
                  ? TextButton(
                      onPressed: () => _cancelInvite(invite.id),
                      child: const Text('Cancel'),
                    )
                  : null,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: invites.length,
        );
      },
    );
  }

  Widget _buildReceivedTab(String email) {
    return StreamBuilder<List<InviteModel>>(
      stream: _inviteService.getReceivedInvitesStream(
        _inviteService.normalizeEmail(email),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }
        if (snapshot.hasError) {
          return _SimpleInviteState(
            title: 'Unable to load received invites',
            subtitle: mapAppErrorMessage(snapshot.error!),
            icon: Icons.cloud_off_rounded,
            onAction: () => setState(() {}),
            actionLabel: 'Retry',
          );
        }
        final invites = snapshot.data ?? const <InviteModel>[];
        if (invites.isEmpty) {
          return const _SimpleInviteState(
            title: 'No received invites yet',
            subtitle: 'When someone invites you, it will show up here.',
            icon: Icons.inbox_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final invite = invites[index];
            return InviteTile(
              title: invite.senderDisplayName ?? invite.senderEmail,
              subtitle: 'Received ${_dateFormatter.format(invite.createdAt)}',
              status: _statusLabel(invite.status),
              trailing: invite.isPending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => _rejectInvite(invite.id),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _acceptInvite(invite.id),
                          child: const Text('Accept'),
                        ),
                      ],
                    )
                  : null,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: invites.length,
        );
      },
    );
  }

  Widget _buildRoommatesTab(String uid) {
    return StreamBuilder<List<RoommateModel>>(
      stream: _firestoreService.getRoommatesStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }
        if (snapshot.hasError) {
          return _SimpleInviteState(
            title: 'Unable to load roommates',
            subtitle: mapAppErrorMessage(snapshot.error!),
            icon: Icons.cloud_off_rounded,
            onAction: () => setState(() {}),
            actionLabel: 'Retry',
          );
        }
        final roommates = snapshot.data ?? const <RoommateModel>[];
        if (roommates.isEmpty) {
          return const _SimpleInviteState(
            title: 'No roommates yet',
            subtitle: 'Accepted invites will appear here as roommates.',
            icon: Icons.people_alt_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final roommate = roommates[index];
            return InviteTile(
              title: roommate.displayName,
              subtitle: roommate.email,
              status: 'Accepted',
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: roommates.length,
        );
      },
    );
  }

  String _statusLabel(InviteStatus status) {
    switch (status) {
      case InviteStatus.accepted:
        return 'Accepted';
      case InviteStatus.rejected:
        return 'Declined';
      case InviteStatus.cancelled:
        return 'Cancelled';
      case InviteStatus.pending:
        return 'Pending';
    }
  }
}

class _SimpleInviteState extends StatelessWidget {
  const _SimpleInviteState({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryAccentBlue, size: 36),
            const SizedBox(height: 12),
            Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class InviteTile extends StatelessWidget {
  const InviteTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DarkCard(
      radius: 16,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBackground(status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: textTheme.bodySmall?.copyWith(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: textTheme.bodySmall,
                ),
              ),
              ..._trailingWidgets(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _trailingWidgets() {
    final item = trailing;
    if (item == null) {
      return const [];
    }
    return [
      const SizedBox(width: 8),
      Flexible(child: item),
    ];
  }

  Color _statusBackground(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return const Color(0xFFE8F8ED);
      case 'declined':
      case 'cancelled':
        return const Color(0xFFFDEBEC);
      default:
        return const Color(0xFFFFF3E8);
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return AppTheme.successGreen;
      case 'declined':
      case 'cancelled':
        return AppTheme.dangerRed;
      default:
        return AppTheme.primaryAccentBlue;
    }
  }
}
