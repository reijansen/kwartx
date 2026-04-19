import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/settlement_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/input_validators.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dark_card.dart';
import '../widgets/profile_info_tile.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final SettlementService _settlementService = const SettlementService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

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
              _fullNameController.text = _isEditing ? _fullNameController.text : profile.fullName;
              _phoneController.text = _isEditing ? _phoneController.text : profile.phoneNumber;
              return FutureBuilder<_ProfileSummaryData>(
                future: _loadSummary(profile),
                builder: (context, summarySnapshot) {
                  final summary = summarySnapshot.data;
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
                            Text('Household Summary', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 10),
                            ProfileInfoTile(label: 'Roommates', value: '${summary?.roommateCount ?? 0}'),
                            ProfileInfoTile(
                              label: 'Total paid',
                              value: Formatters.currency((summary?.paidCents ?? 0) / 100),
                            ),
                            ProfileInfoTile(
                              label: 'Total owed',
                              value: Formatters.currency((summary?.owedCents ?? 0) / 100),
                            ),
                            ProfileInfoTile(
                              label: 'Current balance',
                              value: Formatters.currency((summary?.netCents ?? 0) / 100),
                              highlight: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<_ProfileSummaryData> _loadSummary(UserProfileModel profile) async {
    final expenses = await _firestoreService.getCurrentUserExpenses();
    final roommates = await _firestoreService.getCurrentUserRoommates();
    final participants = await _firestoreService.getParticipantsMapForExpenses(expenses);
    final balances = _settlementService.computeBalances(
      currentUser: profile,
      roommates: roommates,
      expenses: expenses,
      participantsByExpenseId: participants,
    );
    final current = balances.firstWhere(
      (it) => it.userId == profile.id,
      orElse: () => BalanceBucket(
        userId: profile.id,
        fullName: profile.fullName,
        paidCents: 0,
        owedCents: 0,
      ),
    );
    return _ProfileSummaryData(
      roommateCount: roommates.length,
      paidCents: current.paidCents,
      owedCents: current.owedCents,
      netCents: current.netCents,
    );
  }
}

class _ProfileSummaryData {
  const _ProfileSummaryData({
    required this.roommateCount,
    required this.paidCents,
    required this.owedCents,
    required this.netCents,
  });

  final int roommateCount;
  final int paidCents;
  final int owedCents;
  final int netCents;
}
