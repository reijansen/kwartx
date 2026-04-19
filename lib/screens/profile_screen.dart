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
      setState(() {
        _isEditing = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                  DarkCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account Details', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Full Name',
                            hintText: 'Full name',
                            controller: _fullNameController,
                            enabled: _isEditing && !_isSaving,
                            validator: InputValidators.displayName,
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            label: 'Phone Number',
                            hintText: '+63 ...',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: _isEditing && !_isSaving,
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
                          const SizedBox(height: 10),
                          Text(
                            'Member since ${DateFormat('MMM d, y').format(profile.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          if (!_isEditing)
                            PrimaryButton(
                              label: 'Edit Profile',
                              onPressed: () => setState(() => _isEditing = true),
                            )
                          else ...[
                            PrimaryButton(
                              label: 'Save Changes',
                              isLoading: _isSaving,
                              onPressed: _save,
                            ),
                            TextButton(
                              onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        PrimaryButton(
                          label: 'Sign Out',
                          isLoading: _isSigningOut,
                          onPressed: _signOut,
                        ),
                      ],
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
