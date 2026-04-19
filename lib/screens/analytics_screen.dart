import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dark_card.dart';
import '../widgets/modern_empty_state.dart';
import 'expense_form_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<String>(
            future: firestore.getCurrentHouseholdId(),
            builder: (context, householdSnapshot) {
              if (householdSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
              if (householdSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 30, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load analytics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          householdSnapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final uid = householdSnapshot.data ?? '';
              if (uid.isEmpty) {
                return const Center(
                  child: Text(
                    'No active room found. Join or create a room first.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return StreamBuilder<List<ExpenseModel>>(
                stream: firestore.getExpensesStream(uid),
                builder: (context, snapshot) {
                  final expenses = snapshot.data ?? const <ExpenseModel>[];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  }

                  final total = expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
                  final byCategory = <String, int>{};
                  for (final expense in expenses) {
                    byCategory[expense.category] =
                        (byCategory[expense.category] ?? 0) + expense.amountCents;
                  }
                  final sorted = byCategory.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analytics',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    'Track expense trends and categories',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withAlpha(220),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                ExpenseFormScreen.show(context);
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Expense'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryAccentBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4EC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          child: expenses.isEmpty
                              ? const ModernEmptyState(
                                  title: 'No analytics yet',
                                  subtitle: 'Add expenses to see trends and category totals.',
                                  icon: Icons.bar_chart_rounded,
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.heroGradient,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total expenses',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.white.withAlpha(230),
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            Formatters.currency(total / 100),
                                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    DarkCard(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('By category', style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 10),
                                          ...sorted.map(
                                            (entry) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      entry.key,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                  Text(
                                                    Formatters.currency(entry.value / 100),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color: AppTheme.primaryAccentBlue,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
}
