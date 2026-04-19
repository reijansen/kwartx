import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/input_validators.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dark_card.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isSigningOut = false;
  late Future<List<RoomModel>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _firestoreService.getMyRooms();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateCurrentUserProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      await widget.authService.updateDisplayName(_fullNameController.text.trim());
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Profile updated.',
        type: AppFeedbackType.success,
      );
      setState(() => _isEditing = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(error),
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Sign out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign out',
      isDanger: true,
    );
    if (!confirmed) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(error),
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Future<void> _createRoomDialog() async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Room'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Room name',
          ),
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
      showAppSnackBar(context, message: 'Room created.', type: AppFeedbackType.success);
      setState(() {
        _roomsFuture = _firestoreService.getMyRooms();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: mapAppErrorMessage(error), type: AppFeedbackType.error);
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
          decoration: const InputDecoration(
            labelText: 'Room ID',
          ),
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
      showAppSnackBar(context, message: 'Joined room.', type: AppFeedbackType.success);
      setState(() {
        _roomsFuture = _firestoreService.getMyRooms();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: mapAppErrorMessage(error), type: AppFeedbackType.error);
    }
  }

  Future<void> _switchRoom(String roomId) async {
    try {
      await _firestoreService.switchActiveRoom(roomId);
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: 'Active room switched.', type: AppFeedbackType.success);
      setState(() {
        _roomsFuture = _firestoreService.getMyRooms();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: mapAppErrorMessage(error), type: AppFeedbackType.error);
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
      showAppSnackBar(context, message: 'Room left.', type: AppFeedbackType.success);
      setState(() {
        _roomsFuture = _firestoreService.getMyRooms();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: mapAppErrorMessage(error), type: AppFeedbackType.error);
    }
  }

  String _initialsFor(String fullName) {
    final parts = fullName
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<UserProfileModel?>(
            stream: _firestoreService.watchCurrentUserProfile(),
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;
              if (profile == null) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }

              if (!_isEditing) {
                _fullNameController.text = profile.fullName;
                _phoneController.text = profile.phoneNumber;
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Profile',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        _isEditing
                            ? TextButton(
                                onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                                style: TextButton.styleFrom(foregroundColor: Colors.white),
                                child: const Text('Cancel'),
                              )
                            : FilledButton.icon(
                                onPressed: () => setState(() => _isEditing = true),
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryAccentBlue,
                                ),
                              ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initialsFor(profile.fullName),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primaryAccentBlue,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withAlpha(220),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Member since ${DateFormat('MMM y').format(profile.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF4EC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        children: [
                          DarkCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Personal Information', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEditing
                                        ? 'Update your details and tap Save Changes.'
                                        : 'Your profile is synced across roommate activities.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    label: 'Full Name',
                                    hintText: 'Full name',
                                    controller: _fullNameController,
                                    enabled: _isEditing && !_isSaving,
                                    validator: InputValidators.displayName,
                                    prefixIcon: Icons.person_outline_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  CustomTextField(
                                    label: 'Phone Number',
                                    hintText: '+63 ...',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    enabled: _isEditing && !_isSaving,
                                    prefixIcon: Icons.phone_outlined,
                                    validator: (value) {
                                      final trimmed = value?.trim() ?? '';
                                      if (trimmed.isEmpty) {
                                        return 'Phone number is required.';
                                      }
                                      return InputValidators.phone(value);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    initialValue: profile.email,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.mail_outline_rounded),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<List<RoomModel>>(
                            future: _roomsFuture,
                            builder: (context, roomSnapshot) {
                              final rooms = roomSnapshot.data ?? const <RoomModel>[];
                              return DarkCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Rooms',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: _joinRoomDialog,
                                          icon: const Icon(Icons.meeting_room_outlined),
                                          label: const Text('Join'),
                                        ),
                                        FilledButton.icon(
                                          onPressed: _createRoomDialog,
                                          icon: const Icon(Icons.add_rounded),
                                          label: const Text('Create'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (roomSnapshot.connectionState == ConnectionState.waiting)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Center(child: CircularProgressIndicator.adaptive()),
                                      )
                                    else if (rooms.isEmpty)
                                      Text(
                                        'No rooms yet. Create or join one.',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      )
                                    else
                                      ...rooms.map((room) {
                                        final isActive = room.id == profile.householdId;
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(room.name),
                                          subtitle: Text('ID: ${room.id}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isActive)
                                                const Chip(
                                                  label: Text('Active'),
                                                )
                                              else
                                                TextButton(
                                                  onPressed: () => _switchRoom(room.id),
                                                  child: const Text('Switch'),
                                                ),
                                              IconButton(
                                                tooltip: 'Leave room',
                                                onPressed: () => _leaveRoom(room.id),
                                                icon: const Icon(Icons.exit_to_app_rounded),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_isEditing)
                            PrimaryButton(
                              label: 'Save Changes',
                              isLoading: _isSaving,
                              onPressed: _save,
                            ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isSigningOut ? null : _signOut,
                            icon: _isSigningOut
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.logout_rounded),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: AppTheme.dangerRed,
                              side: const BorderSide(color: AppTheme.dangerRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
