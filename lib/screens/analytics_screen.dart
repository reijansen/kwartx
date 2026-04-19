import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dark_card.dart';
import '../widgets/modern_empty_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
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
                    DarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total expenses', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.currency(total / 100),
                            style: Theme.of(context).textTheme.headlineSmall,
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
                                    Expanded(child: Text(entry.key)),
                                    Text(Formatters.currency(entry.value / 100)),
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
