import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invite_model.dart';
import '../models/room_model.dart';
import '../models/roommate_model.dart';
import '../models/user_profile_model.dart';
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

  Future<void> _createRoomDialog() async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Room'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Room name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (created != true) {
      return;
    }
    try {
      await _firestoreService.createRoom(controller.text.trim());
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Room created.',
        type: AppFeedbackType.success,
      );
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(error),
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _joinRoomDialog() async {
    final controller = TextEditingController();
    final join = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Room'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Room ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    if (join != true) {
      return;
    }
    try {
      await _firestoreService.joinRoomById(controller.text.trim());
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Joined room.',
        type: AppFeedbackType.success,
      );
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(error),
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _switchRoom(String roomId) async {
    try {
      await _firestoreService.switchActiveRoom(roomId);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Active room switched.',
        type: AppFeedbackType.success,
      );
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(error),
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _leaveRoom(String roomId) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Leave room',
      message: 'Are you sure you want to leave this room?',
      confirmLabel: 'Leave',
      isDanger: true,
    );
    if (!confirmed) {
      return;
    }
    try {
      await _firestoreService.leaveRoom(roomId);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Room left.',
        type: AppFeedbackType.success,
      );
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(error),
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;
    final email = _currentEmail;
    if (uid == null || uid.isEmpty || email == null || email.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please sign in again to manage invites.')),
      );
    }

    return DefaultTabController(
      initialIndex: widget.initialTabIndex.clamp(0, 3),
      length: 4,
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
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              'Manage invites, members, and rooms',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withAlpha(220),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 96),
                        child: FilledButton.icon(
                          onPressed: _openInviteSheet,
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 18,
                          ),
                          label: const Text('Invite'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryAccentBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
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
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              labelColor: AppTheme.textPrimary,
                              unselectedLabelColor: AppTheme.mutedText,
                              tabs: [
                                Tab(text: 'Sent'),
                                Tab(text: 'Received'),
                                Tab(text: 'Same Room'),
                                Tab(text: 'Rooms'),
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
                              _buildRoomsTab(),
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

  Widget _buildRoomsTab() {
    return StreamBuilder<UserProfileModel?>(
      stream: _firestoreService.watchCurrentUserProfile(),
      builder: (context, profileSnapshot) {
        final activeRoomId = profileSnapshot.data?.householdId ?? '';
        return FutureBuilder<List<RoomModel>>(
          future: _firestoreService.getMyRooms(),
          builder: (context, roomSnapshot) {
            final rooms = roomSnapshot.data ?? const <RoomModel>[];
            if (roomSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator());
            }
            if (roomSnapshot.hasError) {
              return _SimpleInviteState(
                title: 'Unable to load rooms',
                subtitle: mapAppErrorMessage(roomSnapshot.error!),
                icon: Icons.cloud_off_rounded,
                onAction: () => setState(() {}),
                actionLabel: 'Retry',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _joinRoomDialog,
                        icon: const Icon(Icons.meeting_room_outlined),
                        label: const Text('Join Room'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _createRoomDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Room'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rooms.isEmpty)
                  const _SimpleInviteState(
                    title: 'No rooms yet',
                    subtitle:
                        'Create or join a room to start splitting with a group.',
                    icon: Icons.groups_rounded,
                  )
                else
                  ...rooms.map((room) {
                    final isActive = room.id == activeRoomId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoomCard(
                        room: room,
                        isActive: isActive,
                        onSwitch: () => _switchRoom(room.id),
                        onLeave: () => _leaveRoom(room.id),
                        firestoreService: _firestoreService,
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
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
                  ? OutlinedButton(
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
          final message = _mapRoommatesError(snapshot.error!);
          final noRoomState =
              message.toLowerCase().contains('no active room') ||
              message.toLowerCase().contains('not an active member');
          return _SimpleInviteState(
            title: noRoomState
                ? 'No active room yet'
                : 'Unable to load roommates',
            subtitle: message,
            icon: noRoomState ? Icons.groups_rounded : Icons.cloud_off_rounded,
            onAction: noRoomState ? null : () => setState(() {}),
            actionLabel: noRoomState ? null : 'Retry',
          );
        }
        final roommates = snapshot.data ?? const <RoommateModel>[];
        if (roommates.isEmpty) {
          return const _SimpleInviteState(
            title: 'No same-room members yet',
            subtitle: 'Members in your active room will appear here.',
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

  String _mapRoommatesError(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();

      if (message.contains('no household')) {
        return 'No active room yet. Join or create a room from your Profile page.';
      }
      if (message.contains('no active household membership')) {
        return 'You are not an active member of the selected room. Switch or join a room from Profile.';
      }
      if (code.contains('permission-denied')) {
        return 'You do not have permission to read room members.';
      }
      if (code.contains('failed-precondition') || message.contains('index')) {
        return 'Firestore index is missing for room members query. Create the suggested index in Firebase Console.';
      }
    }
    return mapAppErrorMessage(error);
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
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
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

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.isActive,
    required this.onSwitch,
    required this.onLeave,
    required this.firestoreService,
  });

  final RoomModel room;
  final bool isActive;
  final VoidCallback onSwitch;
  final VoidCallback onLeave;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<List<RoommateModel>>(
      future: firestoreService.getRoomMembers(room.id),
      builder: (context, membersSnapshot) {
        final members = membersSnapshot.data ?? const <RoommateModel>[];
        return DarkCard(
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with room name and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${room.id}',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Chip(
                      label: Text('Active'),
                      backgroundColor: Color(0xFFE8F8ED),
                    )
                  else
                    TextButton(
                      onPressed: onSwitch,
                      child: const Text('Switch'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Members section
              if (members.isNotEmpty) ...[
                Text(
                  'Members (${members.length})',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members
                      .map(
                        (member) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2E6DA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  member.displayName,
                                  style: textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onLeave,
                    icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                    label: const Text('Leave'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerRed,
                      side: const BorderSide(color: AppTheme.dangerRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleMedium)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(subtitle, style: textTheme.bodySmall)),
              const SizedBox(width: 12),
              if (trailing != null) trailing!,
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
    return [const SizedBox(width: 8), Flexible(child: item)];
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
