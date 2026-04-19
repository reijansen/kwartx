import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/input_validators.dart';
import '../widgets/app_empty_state.dart';
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
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await _firestoreService.getCurrentUserProfile();
      if (!mounted) {
        return;
      }
      final user = widget.authService.currentUser;
      _displayNameController.text =
          (profile?['displayName'] as String?)?.trim().isNotEmpty == true
          ? (profile!['displayName'] as String).trim()
          : (user?.displayName?.trim() ?? '');
      _phoneController.text = (profile?['phoneNumber'] as String? ?? '').trim();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _loadError = mapAppErrorMessage(
        error,
        fallback: 'Unable to load profile details right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final displayName = _displayNameController.text.trim();
    final phone = _phoneController.text.trim();
    try {
      await _firestoreService.upsertCurrentUserProfile(
        displayName: displayName,
        phoneNumber: phone,
      );
      await widget.authService.updateDisplayName(displayName);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Profile updated successfully.',
        type: AppFeedbackType.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(
          error,
          fallback: 'Unable to save profile right now.',
        ),
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final email = user?.email?.trim() ?? 'No email available';
    final memberSince = user?.metadata.creationTime;
    final memberSinceText = memberSince == null
        ? null
        : DateFormat('MMM d, y').format(memberSince);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppEmptyState(
                      title: 'Could not load profile',
                      subtitle: _loadError!,
                      icon: Icons.person_off_rounded,
                      actionLabel: 'Retry',
                      onActionPressed: _loadProfile,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DarkCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your details',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Update your profile information below.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.mutedText),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Full name',
                              hintText: 'Enter your name',
                              prefixIcon: Icons.person_outline_rounded,
                              controller: _displayNameController,
                              enabled: !_isSaving,
                              textInputAction: TextInputAction.next,
                              validator: InputValidators.displayName,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              label: 'Phone number',
                              hintText: '+1 555 123 4567',
                              prefixIcon: Icons.call_outlined,
                              controller: _phoneController,
                              enabled: !_isSaving,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              validator: InputValidators.phone,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              readOnly: true,
                              initialValue: email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                            if (memberSinceText != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Member since $memberSinceText',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.mutedText),
                              ),
                            ],
                            const SizedBox(height: 18),
                            PrimaryButton(
                              label: 'Save profile',
                              isLoading: _isSaving,
                              onPressed: _saveProfile,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
