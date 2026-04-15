import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invite_model.dart';
import '../services/invite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/dark_card.dart';
import '../widgets/invite_form_sheet.dart';

class InviteRoommateScreen extends StatefulWidget {
  const InviteRoommateScreen({super.key});

  @override
  State<InviteRoommateScreen> createState() => _InviteRoommateScreenState();
}

class _InviteRoommateScreenState extends State<InviteRoommateScreen> {
  final InviteService _inviteService = InviteService();
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

    try {
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _InlineStateMessage(
                title: 'Account email unavailable',
                subtitle: 'Please sign in again to manage invites.',
                icon: Icons.mark_email_unread_outlined,
              ),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.navOverlay.withAlpha(200),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.glowOutlineBlue.withAlpha(70),
                  ),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppTheme.glowOutlineBlue.withAlpha(65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondaryAccentBlue),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: AppTheme.textPrimary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  splashBorderRadius: BorderRadius.circular(12),
                  tabs: const [
                    Tab(text: 'Sent'),
                    Tab(text: 'Received'),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openInviteSheet,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Invite'),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
          child: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                StreamBuilder<List<InviteModel>>(
                  stream: _inviteService.getSentInvitesStream(uid),
                  builder: (context, snapshot) {
                    return _InvitesListSection(
                      snapshot: snapshot,
                      emptyTitle: 'No invites yet',
                      emptySubtitle: 'Invite a roommate to get started.',
                      emptyIcon: Icons.mail_outline_rounded,
                      errorTitle: 'Failed to load invites',
                      errorSubtitle: 'Please try again.',
                      errorIcon: Icons.cloud_off_rounded,
                      onRetry: () => setState(() {}),
                      itemBuilder: (invite) => _InviteListItem(
                        headline: invite.recipientEmail,
                        subtitle:
                            'Sent ${_dateFormatter.format(invite.createdAt)}',
                        message: invite.message,
                        statusLabel: _statusLabel(invite.status),
                        statusColor: _statusColor(invite.status),
                        trailing: invite.isPending
                            ? TextButton(
                                onPressed: () => _cancelInvite(invite.id),
                                child: const Text('Cancel'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
                StreamBuilder<List<InviteModel>>(
                  stream: _inviteService.getReceivedInvitesStream(
                    normalizedEmail,
                  ),
                  builder: (context, snapshot) {
                    return _InvitesListSection(
                      snapshot: snapshot,
                      emptyTitle: 'No invites yet',
                      emptySubtitle: 'Invites sent to your email appear here.',
                      emptyIcon: Icons.mark_email_unread_outlined,
                      errorTitle: 'Failed to load invites',
                      errorSubtitle: 'Please try again.',
                      errorIcon: Icons.cloud_off_rounded,
                      onRetry: () => setState(() {}),
                      itemBuilder: (invite) => _InviteListItem(
                        headline: invite.senderEmail,
                        subtitle:
                            'Received ${_dateFormatter.format(invite.createdAt)}',
                        message: invite.message,
                        statusLabel: _statusLabel(invite.status),
                        statusColor: _statusColor(invite.status),
                        trailing: invite.isPending
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _rejectInvite(invite.id),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 4),
                                  FilledButton(
                                    onPressed: () => _acceptInvite(invite.id),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitesListSection extends StatelessWidget {
  const _InvitesListSection({
    required this.snapshot,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.errorTitle,
    required this.errorSubtitle,
    required this.errorIcon,
    required this.onRetry,
    required this.itemBuilder,
  });

  final AsyncSnapshot<List<InviteModel>> snapshot;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final String errorTitle;
  final String errorSubtitle;
  final IconData errorIcon;
  final VoidCallback onRetry;
  final Widget Function(InviteModel invite) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: AppLoadingIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _InlineStateMessage(
            title: errorTitle,
            subtitle: errorSubtitle,
            icon: errorIcon,
            actionLabel: 'Retry',
            onActionPressed: onRetry,
          ),
        ),
      );
    }

    final invites = snapshot.data ?? <InviteModel>[];
    if (invites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _InlineStateMessage(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: emptyIcon,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: invites.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => itemBuilder(invites[index]),
    );
  }
}

class _InviteListItem extends StatelessWidget {
  const _InviteListItem({
    required this.headline,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    this.message,
    this.trailing,
  });

  final String headline;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final String? message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DarkCard(
      radius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
          ),
          if ((message ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message!.trim(),
              style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: trailing!),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withAlpha(36),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InlineStateMessage extends StatelessWidget {
  const _InlineStateMessage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.navOverlay,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.glowOutlineBlue.withAlpha(80)),
          ),
          child: Icon(icon, color: AppTheme.secondaryAccentBlue),
        ),
        const SizedBox(height: 12),
        Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onActionPressed != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onActionPressed, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}
