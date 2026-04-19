import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/roommate_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
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
  bool _isEditing = false;
  String? _loadError;
  List<RoommateModel> _roommates = const [];
  List<ExpenseModel> _expenses = const [];

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
      final data = await Future.wait([
        _firestoreService.getCurrentUserProfile(),
        _firestoreService.getCurrentUserRoommates(),
        _firestoreService.getCurrentUserExpenses(),
      ]);
      final profile = data[0] as Map<String, dynamic>?;
      _roommates = data[1] as List<RoommateModel>;
      _expenses = data[2] as List<ExpenseModel>;
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
      setState(() {
        _isEditing = false;
      });
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
    final userDisplay = (user?.displayName ?? '').trim().toLowerCase();
    final emailLower = (user?.email ?? '').trim().toLowerCase();
    final totalPaid = _expenses
        .where((expense) {
          final paidBy = expense.paidBy.trim().toLowerCase();
          return paidBy == userDisplay || paidBy == emailLower;
        })
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final totalOwed = _expenses.fold<double>(
      0,
      (sum, expense) => sum + (expense.amount / (expense.splitCount <= 0 ? 1 : expense.splitCount)),
    );
    final netBalance = totalPaid - totalOwed;
    final householdName = '${email.split('@').first} Household';

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
                            const SizedBox(height: 10),
                            Text(
                              'Household: $householdName',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Roommates: ${_roommates.length}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Full name',
                              hintText: 'Enter your name',
                              prefixIcon: Icons.person_outline_rounded,
                              controller: _displayNameController,
                              enabled: _isEditing && !_isSaving,
                              textInputAction: TextInputAction.next,
                              validator: InputValidators.displayName,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              label: 'Phone number',
                              hintText: '+1 555 123 4567',
                              prefixIcon: Icons.call_outlined,
                              controller: _phoneController,
                              enabled: _isEditing && !_isSaving,
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
                            const SizedBox(height: 14),
                            _ProfileStatRow(
                              label: 'Total paid',
                              value: Formatters.currency(totalPaid),
                            ),
                            const SizedBox(height: 6),
                            _ProfileStatRow(
                              label: 'Total owed',
                              value: Formatters.currency(totalOwed),
                            ),
                            const SizedBox(height: 6),
                            _ProfileStatRow(
                              label: 'Current balance',
                              value: Formatters.currency(netBalance),
                              highlight: true,
                            ),
                            const SizedBox(height: 18),
                            if (!_isEditing)
                              PrimaryButton(
                                label: 'Edit profile',
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                              )
                            else ...[
                              PrimaryButton(
                                label: 'Save profile',
                                isLoading: _isSaving,
                                onPressed: _saveProfile,
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          _isEditing = false;
                                        });
                                        _loadProfile();
                                      },
                                child: const Text('Cancel'),
                              ),
                            ],
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

class _ProfileStatRow extends StatelessWidget {
  const _ProfileStatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: highlight ? AppTheme.secondaryAccentBlue : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
