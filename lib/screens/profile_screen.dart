import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isEditing
                ? TextButton(
                    onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  )
                : FilledButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
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

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33FF7D4D),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(220),
                            shape: BoxShape.circle,
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Member since ${DateFormat('MMM y').format(profile.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
