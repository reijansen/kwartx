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

class BalanceDetailScreen extends StatelessWidget {
  const BalanceDetailScreen({
    super.key,
    required this.heroTag,
  });

  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final enabled = appAnimationsEnabled(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestore = FirestoreService();
    final settlementService = const SettlementService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: uid.isEmpty
              ? const Center(child: Text('Session unavailable.'))
              : FutureBuilder<UserProfileModel?>(
                  future: firestore.getCurrentUserProfileModel(),
                  builder: (context, profileSnapshot) {
                    final profile = profileSnapshot.data;
                    if (profileSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }
                    if (profile == null) {
                      return const Center(child: Text('Could not load profile.'));
                    }

                    return StreamBuilder<List<RoommateModel>>(
                      stream: firestore.getRoommatesStream(uid),
                      builder: (context, roommatesSnapshot) {
                        final roommates = roommatesSnapshot.data ?? const <RoommateModel>[];
                        return StreamBuilder<List<ExpenseModel>>(
                          stream: firestore.getExpensesStream(uid),
                          builder: (context, expensesSnapshot) {
                            final expenses = expensesSnapshot.data ?? const <ExpenseModel>[];
                            return FutureBuilder<Map<String, List<ExpenseParticipantModel>>>(
                              future: firestore.getParticipantsMapForExpenses(expenses),
                              builder: (context, participantsSnapshot) {
                                final participantsByExpenseId = participantsSnapshot.data ?? const {};
                                final balances = settlementService.computeBalances(
                                  currentUser: profile,
                                  roommates: roommates,
                                  expenses: expenses,
                                  participantsByExpenseId: participantsByExpenseId,
                                );

                                final currentBucket = balances.firstWhere(
                                  (b) => b.userId == profile.id,
                                  orElse: () => BalanceBucket(
                                    userId: profile.id,
                                    fullName: profile.fullName,
                                    paidCents: 0,
                                    owedCents: 0,
                                  ),
                                );

                                final net = currentBucket.netCents;
                                final accent = net < 0
                                    ? AppTheme.dangerRed
                                    : net > 0
                                    ? AppTheme.successGreen
                                    : AppTheme.secondaryAccentBlue;

                                final byMonth = _monthTotals(expenses);
                                final trend = _lastMonths(byMonth, count: 6);

                                final topPayer = balances.isEmpty
                                    ? null
                                    : (balances.toList()..sort((a, b) => b.paidCents.compareTo(a.paidCents))).first;

                                return ListView(
                                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          icon: const Icon(Icons.arrow_back_rounded),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('Balance', style: Theme.of(context).textTheme.titleLarge),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    DarkCard(
                                      radius: 22,
                                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                                      child: Column(
                                        children: [
                                          RadialHero(
                                            tag: heroTag,
                                            enabled: enabled,
                                            maxRadius: 90,
                                            child: Container(
                                              width: 108,
                                              height: 108,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: accent.withAlpha(26),
                                                border: Border.all(color: accent.withAlpha(90)),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                Formatters.currency(net.abs() / 100),
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      color: accent,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            net < 0
                                                ? 'You owe overall'
                                                : net > 0
                                                ? 'You are owed overall'
                                                : 'All settled up overall',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text('Monthly breakdown', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 10),
                                    if (trend.isEmpty)
                                      Text(
                                        'No expenses yet to build a breakdown.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                                      )
                                    else
                                      DarkCard(
                                        radius: 18,
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          children: trend.map((it) {
                                            final monthLabel = DateFormat('MMM y').format(it.month);
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(monthLabel, style: Theme.of(context).textTheme.bodyMedium),
                                                  ),
                                                  Text(
                                                    Formatters.currency(it.totalCents / 100),
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    const SizedBox(height: 14),
                                    Text('Per-roommate totals', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 10),
                                    if (balances.isEmpty)
                                      Text(
                                        'No balances computed yet.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                                      )
                                    else
                                      ...balances.where((b) => b.userId != profile.id).map((b) {
                                        final netCents = b.netCents;
                                        final color = netCents < 0
                                            ? AppTheme.dangerRed
                                            : netCents > 0
                                            ? AppTheme.successGreen
                                            : AppTheme.secondaryAccentBlue;
                                        final label = netCents < 0
                                            ? 'You likely owe'
                                            : netCents > 0
                                            ? 'Likely owes you'
                                            : 'Settled';
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: DarkCard(
                                            radius: 18,
                                            padding: const EdgeInsets.all(14),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: color.withAlpha(28),
                                                  child: Icon(
                                                    netCents < 0
                                                        ? Icons.call_made_rounded
                                                        : netCents > 0
                                                        ? Icons.call_received_rounded
                                                        : Icons.check_rounded,
                                                    color: color,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(b.fullName, style: Theme.of(context).textTheme.titleSmall),
                                                      Text(
                                                        label,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  Formatters.currency(netCents.abs() / 100),
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        color: color,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    const SizedBox(height: 6),
                                    if (topPayer != null)
                                      DarkCard(
                                        radius: 18,
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.emoji_events_outlined, color: AppTheme.secondaryAccentBlue),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Top payer: ${topPayer.fullName}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                            Text(
                                              Formatters.currency(topPayer.paidCents / 100),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                                            ),
                                          ],
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
                  },
                ),
        ),
      ),
    );
  }
}

class _MonthTotal {
  const _MonthTotal({required this.month, required this.totalCents});
  final DateTime month;
  final int totalCents;
}

Map<DateTime, int> _monthTotals(List<ExpenseModel> expenses) {
  final map = <DateTime, int>{};
  for (final e in expenses) {
    final month = DateTime(e.date.year, e.date.month);
    map[month] = (map[month] ?? 0) + e.amountCents;
  }
  return map;
}

List<_MonthTotal> _lastMonths(Map<DateTime, int> totals, {required int count}) {
  final keys = totals.keys.toList()..sort((a, b) => a.compareTo(b));
  if (keys.isEmpty) {
    return const [];
  }
  final tail = keys.length <= count ? keys : keys.sublist(keys.length - count);
  return tail.map((m) => _MonthTotal(month: m, totalCents: totals[m] ?? 0)).toList();
}

