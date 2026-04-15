import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import 'expense_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormatter = DateFormat('MMM d, y');
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.authService.signOut();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _openExpenseForm({
    required String title,
    ExpenseModel? expense,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExpenseFormScreen(title: title, existingExpense: expense),
      ),
    );
  }

  Future<bool> _confirmDelete(ExpenseModel expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Delete Expense'),
          content: Text('Delete "${expense.title}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.dangerRed),
              ),
            ),
          ],
        );
      },
    );

    return shouldDelete ?? false;
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final shouldDelete = await _confirmDelete(expense);
    if (!shouldDelete) {
      return;
    }

    try {
      await _firestoreService.deleteExpense(expense.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense deleted.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete expense.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = widget.authService.currentUser;
    final uid = user?.uid;
    final email = user?.email ?? 'user@kwartx.app';

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
          child: const Center(
            child: Text('Session unavailable. Please sign in again.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('KwartX'),
        actions: [
          IconButton(
            onPressed: _isSigningOut ? null : _handleSignOut,
            tooltip: 'Logout',
            icon: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textPrimary,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: StreamBuilder<List<ExpenseModel>>(
            stream: _firestoreService.getExpensesStream(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.secondaryAccentBlue,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Unable to load expenses right now.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final expenses = snapshot.data ?? [];
              final monthTotal = expenses
                  .where(
                    (expense) =>
                        expense.createdAt.year == DateTime.now().year &&
                        expense.createdAt.month == DateTime.now().month,
                  )
                  .fold<double>(0, (sum, expense) => sum + expense.amount);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              style: textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.navOverlay,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.glowOutlineBlue.withAlpha(170),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DarkCard(
                    radius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shared expenses',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('This month', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text(
                          '\$${monthTotal.toStringAsFixed(2)}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Quick actions', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Add',
                        onTap: () => _openExpenseForm(title: 'Add Expense'),
                      ),
                      _QuickAction(
                        icon: Icons.call_split_rounded,
                        label: 'Split',
                        onTap: () => _openExpenseForm(title: 'Split Bill'),
                      ),
                      _QuickAction(
                        icon: Icons.bar_chart_rounded,
                        label: 'Summary',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Summary view is coming soon.'),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.more_horiz_rounded,
                        label: 'More',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('More actions are coming soon.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Recent expenses', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    DarkCard(
                      radius: 16,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No expenses yet. Add your first expense.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ...expenses.map((expense) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(expense),
                        onDismissed: (_) => _deleteExpense(expense),
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withAlpha(180),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _openExpenseForm(
                              title: 'Edit Expense',
                              expense: expense,
                            );
                          },
                          child: DarkCard(
                            radius: 16,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${expense.paidBy} - ${expense.category}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dateFormatter.format(
                                          expense.createdAt,
                                        ),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '\$${expense.amount.toStringAsFixed(2)}',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.navOverlay,
                border: Border.all(
                  color: AppTheme.glowOutlineBlue.withAlpha(140),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x442D7DFF),
                    blurRadius: 16,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.secondaryAccentBlue),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
