import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/expense_participant_model.dart';
import '../models/roommate_model.dart';
import '../models/settlement_view_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/settlement_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_feedback.dart';
import 'expense_form_screen.dart';
import 'invite_roommate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final SettlementService _settlementService = const SettlementService();

  Future<void> _openExpenseForm({ExpenseModel? expense}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseFormScreen(existingExpense: expense),
      ),
    );
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete expense',
      message: 'Are you sure you want to delete "${expense.title}"?',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (!confirmed) {
      return;
    }
    await _firestoreService.deleteExpense(expense.id);
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: 'Expense deleted.',
      type: AppFeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Session unavailable. Please sign in again.'),
        ),
      );
    }

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
              return StreamBuilder<List<RoommateModel>>(
                stream: _firestoreService.getRoommatesStream(uid),
                builder: (context, roommatesSnapshot) {
                  final roommates = roommatesSnapshot.data ?? const <RoommateModel>[];
                  return StreamBuilder<List<ExpenseModel>>(
                    stream: _firestoreService.getExpensesStream(uid),
                    builder: (context, expensesSnapshot) {
                      final expenses = expensesSnapshot.data ?? const <ExpenseModel>[];
                      if (expensesSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator.adaptive());
                      }

                      return FutureBuilder<Map<String, List<ExpenseParticipantModel>>>(
                        future: _firestoreService.getParticipantsMapForExpenses(expenses),
                        builder: (context, participantsSnapshot) {
                          final participantsMap = participantsSnapshot.data ?? const {};
                          final balances = _settlementService.computeBalances(
                            currentUser: profile,
                            roommates: roommates,
                            expenses: expenses,
                            participantsByExpenseId: participantsMap,
                          );
                          final settlements = _settlementService.simplifyDebts(balances);

                          final currentBucket = balances.firstWhere(
                            (bucket) => bucket.userId == profile.id,
                            orElse: () => BalanceBucket(
                              userId: profile.id,
                              fullName: profile.fullName,
                              paidCents: 0,
                              owedCents: 0,
                            ),
                          );

                          return RefreshIndicator(
                            color: AppTheme.primaryAccentBlue,
                            onRefresh: () async => setState(() {}),
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(14, 6, 14, 120),
                              children: [
                                _HomeTopBar(name: profile.fullName),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MiniBalanceCard(
                                        title: 'You Owe',
                                        amount: Formatters.currency(currentBucket.youOweCents / 100),
                                        icon: Icons.north_east_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _MiniBalanceCard(
                                        title: 'Owes you',
                                        amount: Formatters.currency(currentBucket.youAreOwedCents / 100),
                                        icon: Icons.south_west_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SectionHeader(
                                  title: 'Pending Bills',
                                  actionText: 'View All',
                                  onTap: () {},
                                ),
                                const SizedBox(height: 8),
                                if (expenses.isEmpty)
                                  _SoftEmptyCard(
                                    title: 'Add your first expense to get started',
                                    subtitle: 'Track shared costs and balances with roommates.',
                                    actionLabel: 'Add Expense',
                                    onAction: () => _openExpenseForm(),
                                  )
                                else
                                  ...expenses.take(3).map((expense) {
                                    final status = _expenseStatus(profile.id, expense, participantsMap[expense.id] ?? const []);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _PendingBillCard(
                                        expense: expense,
                                        status: status,
                                        onTap: () => _openExpenseForm(expense: expense),
                                        onDelete: () => _deleteExpense(expense),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EFE8),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Friends', style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 10),
                                      if (roommates.isEmpty)
                                        _SoftEmptyCard(
                                          title: 'Invite roommates to start splitting',
                                          subtitle: 'Connect your household so paid-by and settlements work.',
                                          actionLabel: 'Invite Roommates',
                                          onAction: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) => const InviteRoommateScreen(),
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        ...roommates.take(5).map((mate) {
                                          final summary = _roommateSummary(
                                            currentUserId: profile.id,
                                            roommate: mate,
                                            settlements: settlements,
                                          );
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: _FriendTile(
                                              name: mate.displayName,
                                              subtitle: summary.text,
                                              positive: summary.positive,
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  _ExpenseStatus _expenseStatus(
    String currentUserId,
    ExpenseModel expense,
    List<ExpenseParticipantModel> participants,
  ) {
    final myParticipant = participants.where((it) => it.userId == currentUserId).cast<ExpenseParticipantModel?>().firstWhere(
          (it) => it != null,
          orElse: () => null,
        );

    final participantCount = expense.participantUserIds.isNotEmpty ? expense.participantUserIds.length : (participants.isEmpty ? 1 : participants.length);
    final fallbackShare = participantCount <= 0 ? 0 : (expense.amountCents / participantCount).round();
    final myShare = myParticipant?.exactCents ?? fallbackShare;

    if (expense.paidByUserId == currentUserId) {
      final receivable = (expense.amountCents - myShare).clamp(0, expense.amountCents);
      if (receivable == 0) {
        return const _ExpenseStatus(text: 'Settled up', amountCents: 0, positive: null);
      }
      return _ExpenseStatus(text: 'You are owed', amountCents: receivable, positive: true);
    }

    if (myShare <= 0) {
      return const _ExpenseStatus(text: 'Not involved', amountCents: 0, positive: null);
    }
    return _ExpenseStatus(text: 'You owe', amountCents: myShare, positive: false);
  }

  _RoommateSummary _roommateSummary({
    required String currentUserId,
    required RoommateModel roommate,
    required List<SettlementViewModel> settlements,
  }) {
    final roommateId = roommate.linkedUid ?? roommate.id;
    int youOweCents = 0;
    int owesYouCents = 0;

    for (final tx in settlements) {
      if (tx.fromUserId == currentUserId && tx.toUserId == roommateId) {
        youOweCents += tx.amountCents;
      }
      if (tx.fromUserId == roommateId && tx.toUserId == currentUserId) {
        owesYouCents += tx.amountCents;
      }
    }

    if (owesYouCents > 0) {
      return _RoommateSummary(text: 'Owes you ${Formatters.currency(owesYouCents / 100)}', positive: true);
    }
    if (youOweCents > 0) {
      return _RoommateSummary(text: 'You owe ${Formatters.currency(youOweCents / 100)}', positive: false);
    }
    return const _RoommateSummary(text: 'Settled up', positive: null);
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Row(
      children: [
        const Icon(Icons.pie_chart_rounded, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          'KwartX',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(45),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(45),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            firstName.isEmpty ? 'U' : firstName[0].toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _MiniBalanceCard extends StatelessWidget {
  const _MiniBalanceCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171616),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
              Icon(icon, color: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onTap,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        const Spacer(),
        if (actionText != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              actionText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _PendingBillCard extends StatelessWidget {
  const _PendingBillCard({
    required this.expense,
    required this.status,
    required this.onTap,
    required this.onDelete,
  });

  final ExpenseModel expense;
  final _ExpenseStatus status;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEAD9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.home_work_rounded, color: AppTheme.primaryAccentBlue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.title, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          DateFormat('MMM d, y').format(expense.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.currency(expense.amount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: status.positive == null
                      ? const Color(0xFFF2EFE8)
                      : (status.positive! ? const Color(0xFFD2F2D7) : const Color(0xFFF7DDE0)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: status.positive == null
                                  ? AppTheme.textSecondary
                                  : (status.positive! ? AppTheme.successGreen : AppTheme.dangerRed),
                            ),
                      ),
                    ),
                    if (status.amountCents > 0)
                      Text(
                        Formatters.currency(status.amountCents / 100),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: status.positive == null
                                  ? AppTheme.textSecondary
                                  : (status.positive! ? AppTheme.successGreen : AppTheme.dangerRed),
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftEmptyCard extends StatelessWidget {
  const _SoftEmptyCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.name,
    required this.subtitle,
    required this.positive,
  });

  final String name;
  final String subtitle;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAD9),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? 'R' : name[0].toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryAccentBlue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: positive == null
                            ? AppTheme.mutedText
                            : (positive! ? AppTheme.successGreen : AppTheme.dangerRed),
                        fontWeight: positive == null ? FontWeight.w500 : FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _ExpenseStatus {
  const _ExpenseStatus({
    required this.text,
    required this.amountCents,
    required this.positive,
  });

  final String text;
  final int amountCents;
  final bool? positive;
}

class _RoommateSummary {
  const _RoommateSummary({
    required this.text,
    required this.positive,
  });

  final String text;
  final bool? positive;
}
