import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/expense_participant_model.dart';
import '../models/roommate_model.dart';
import '../models/user_profile_model.dart';
import '../services/firestore_service.dart';
import '../services/settlement_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dark_card.dart';
import '../widgets/radial_hero.dart';

class RoommateDetailScreen extends StatelessWidget {
  const RoommateDetailScreen({
    super.key,
    required this.roommate,
    required this.heroTag,
  });

  final RoommateModel roommate;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final enabled = appAnimationsEnabled(context);
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = authUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: uid.isEmpty
              ? const Center(child: Text('Session unavailable.'))
              : _RoommateDetailBody(
                  roommate: roommate,
                  heroTag: heroTag,
                  animationsEnabled: enabled,
                  currentUserId: uid,
                ),
        ),
      ),
    );
  }
}

class _RoommateDetailBody extends StatelessWidget {
  const _RoommateDetailBody({
    required this.roommate,
    required this.heroTag,
    required this.animationsEnabled,
    required this.currentUserId,
  });

  final RoommateModel roommate;
  final String heroTag;
  final bool animationsEnabled;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final settlementService = const SettlementService();

    return FutureBuilder<UserProfileModel?>(
      future: firestore.getCurrentUserProfileModel(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (profile == null) {
          return const Center(child: Text('Could not load profile.'));
        }

        return StreamBuilder<List<ExpenseModel>>(
          stream: firestore.getExpensesStream(currentUserId),
          builder: (context, expensesSnapshot) {
            final expenses = expensesSnapshot.data ?? const <ExpenseModel>[];
            return FutureBuilder<Map<String, List<ExpenseParticipantModel>>>(
              future: firestore.getParticipantsMapForExpenses(expenses),
              builder: (context, participantsSnapshot) {
                final participantsByExpenseId = participantsSnapshot.data ?? const {};
                final balances = settlementService.computeBalances(
                  currentUser: profile,
                  roommates: [roommate],
                  expenses: expenses,
                  participantsByExpenseId: participantsByExpenseId,
                );
                final settlements = settlementService.simplifyDebts(balances);

                final roommateId = roommate.linkedUid ?? roommate.id;
                final youOweCents = settlements
                    .where((tx) => tx.fromUserId == profile.id && tx.toUserId == roommateId)
                    .fold<int>(0, (sum, tx) => sum + tx.amountCents);
                final owesYouCents = settlements
                    .where((tx) => tx.fromUserId == roommateId && tx.toUserId == profile.id)
                    .fold<int>(0, (sum, tx) => sum + tx.amountCents);

                final sharedExpenses = expenses.where((expense) {
                  if (expense.paidByUserId == roommateId) {
                    return true;
                  }
                  if (expense.participantUserIds.contains(roommateId)) {
                    return true;
                  }
                  if (expense.paidByUserId == profile.id && expense.participantUserIds.contains(roommateId)) {
                    return true;
                  }
                  return false;
                }).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 4),
                            Text('Roommate', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                        child: DarkCard(
                          radius: 22,
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Column(
                            children: [
                              RadialHero(
                                tag: heroTag,
                                enabled: animationsEnabled,
                                maxRadius: 64,
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.secondaryAccentBlue.withAlpha(55),
                                  child: Text(
                                    _initials(roommate.displayName),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                roommate.displayName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                roommate.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatusPill(
                                      label: owesYouCents > 0
                                          ? 'Owes you'
                                          : youOweCents > 0
                                          ? 'You owe'
                                          : 'Settled up',
                                      amount: owesYouCents > 0
                                          ? Formatters.currency(owesYouCents / 100)
                                          : youOweCents > 0
                                          ? Formatters.currency(youOweCents / 100)
                                          : null,
                                      positive: owesYouCents > 0
                                          ? true
                                          : youOweCents > 0
                                          ? false
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: Text('Shared expenses', style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                    if (sharedExpenses.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                          child: Text(
                            'No shared expenses found yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                        sliver: SliverList.separated(
                          itemCount: sharedExpenses.length.clamp(0, 12),
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final expense = sharedExpenses[index];
                            return DarkCard(
                              radius: 18,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E9),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(expense.title, style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('MMM d, y').format(expense.date),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(expense.amount),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((it) => it.isNotEmpty);
    final letters = parts.take(2).map((it) => it[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.amount,
    required this.positive,
  });

  final String label;
  final String? amount;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    final bg = positive == null
        ? const Color(0xFFF2EFE8)
        : (positive! ? const Color(0xFFD2F2D7) : const Color(0xFFF7DDE0));
    final fg = positive == null
        ? AppTheme.textSecondary
        : (positive! ? AppTheme.successGreen : AppTheme.dangerRed);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
            ),
          ),
          if (amount != null)
            Text(
              amount!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
            ),
        ],
      ),
    );
  }
}
