import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../models/expense_participant_model.dart';
import '../models/roommate_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/settlement_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_feedback.dart';
import '../widgets/expense_list_item.dart';
import '../widgets/gradient_balance_card.dart';
import '../widgets/modern_empty_state.dart';
import '../widgets/settlement_tile.dart';
import '../widgets/stat_card.dart';
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

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'rent':
        return Icons.home_work_outlined;
      case 'electricity':
        return Icons.bolt_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'wifi':
        return Icons.wifi_outlined;
      case 'groceries':
        return Icons.shopping_bag_outlined;
      case 'repairs':
        return Icons.build_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
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
      appBar: AppBar(
        title: const Text('KwartX'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _openExpenseForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
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
                          final heroTitle = currentBucket.netCents < 0
                              ? 'You owe'
                              : currentBucket.netCents > 0
                                  ? 'You are owed'
                                  : 'All settled up';

                          return RefreshIndicator(
                            onRefresh: () async => setState(() {}),
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                              children: [
                                Text(
                                  'Welcome back, ${profile.fullName.split(' ').first}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                GradientBalanceCard(
                                  title: heroTitle,
                                  amountLabel: Formatters.currency(currentBucket.netCents.abs() / 100),
                                  subtitle: currentBucket.netCents == 0
                                      ? 'No unsettled balance right now.'
                                      : 'Based on current household expenses.',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StatCard(
                                        label: 'You owe',
                                        value: Formatters.currency(currentBucket.youOweCents / 100),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: StatCard(
                                        label: 'You are owed',
                                        value: Formatters.currency(currentBucket.youAreOwedCents / 100),
                                      ),
                                    ),
                                  ],
                                ),
                                if (roommates.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  ModernEmptyState(
                                    title: 'Invite roommates to start splitting expenses',
                                    subtitle:
                                        'Add your household members so paid-by and settlements work correctly.',
                                    icon: Icons.group_add_rounded,
                                    actionLabel: 'Invite roommates',
                                    onAction: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const InviteRoommateScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Text('Settlements', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                if (settlements.isEmpty)
                                  const ModernEmptyState(
                                    title: 'All settled up',
                                    subtitle: 'No one owes anything right now.',
                                    icon: Icons.check_circle_outline_rounded,
                                  )
                                else
                                  ...settlements.take(6).map((settlement) {
                                    final isYouDebtor = settlement.fromUserId == profile.id;
                                    final isYouCreditor = settlement.toUserId == profile.id;
                                    final label = isYouDebtor
                                        ? 'You owe ${settlement.toName}'
                                        : isYouCreditor
                                            ? '${settlement.fromName} owes you'
                                            : '${settlement.fromName} owes ${settlement.toName}';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: SettlementTile(
                                        label: label,
                                        amount: Formatters.currency(settlement.amountCents / 100),
                                        positive: isYouCreditor,
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 12),
                                Text('Recent expenses', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                if (expenses.isEmpty)
                                  ModernEmptyState(
                                    title: 'Add your first expense to get started',
                                    subtitle: 'Track shared costs and settlements will appear automatically.',
                                    icon: Icons.receipt_long_outlined,
                                    actionLabel: 'Add expense',
                                    onAction: () => _openExpenseForm(),
                                  )
                                else
                                  ...expenses.take(10).map((expense) {
                                    final isMine = expense.paidByUserId == profile.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Dismissible(
                                        key: ValueKey(expense.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dangerRed.withAlpha(20),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(Icons.delete_outline_rounded),
                                        ),
                                        confirmDismiss: (_) async {
                                          await _deleteExpense(expense);
                                          return false;
                                        },
                                        child: ExpenseListItem(
                                          icon: _iconForCategory(expense.category),
                                          title: expense.title,
                                          subtitle:
                                              '${expense.paidByName} - ${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}',
                                          amount: Formatters.currency(expense.amount),
                                          isPositive: isMine,
                                          onTap: () => _openExpenseForm(expense: expense),
                                        ),
                                      ),
                                    );
                                  }),
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
}
