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
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExpenseFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: FutureBuilder<String>(
          future: firestore.getCurrentHouseholdId(),
          builder: (context, householdSnapshot) {
            final uid = householdSnapshot.data ?? '';
            if (uid.isEmpty) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            return StreamBuilder<List<ExpenseModel>>(
              stream: firestore.getExpensesStream(uid),
              builder: (context, snapshot) {
                final expenses = snapshot.data ?? const <ExpenseModel>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }
                if (expenses.isEmpty) {
                  return const ModernEmptyState(
                    title: 'No analytics yet',
                    subtitle: 'Add expenses to see trends and category totals.',
                    icon: Icons.bar_chart_rounded,
                  );
                }
                final total = expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
                final byCategory = <String, int>{};
                for (final expense in expenses) {
                  byCategory[expense.category] =
                      (byCategory[expense.category] ?? 0) + expense.amountCents;
                }
                final sorted = byCategory.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF7D4D),
                            blurRadius: 14,
                            offset: Offset(0, 7),
                          ),
                        ],
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
                          ...sorted.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      Formatters.currency(entry.value / 100),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.primaryAccentBlue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              )),
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
    );
  }
}
