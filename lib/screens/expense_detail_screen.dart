import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/expense_participant_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dark_card.dart';
import '../widgets/radial_hero.dart';
import 'expense_form_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.heroTag,
  });

  final ExpenseModel expense;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final enabled = appAnimationsEnabled(context);
    final firestore = FirestoreService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text('Expense', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () async {
                      await ExpenseFormScreen.show(
                        context,
                        existingExpense: expense,
                      );
                    },
                    icon: const Icon(Icons.edit_rounded),
                  ),
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
                      maxRadius: 62,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expense.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.currency(expense.amount),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat('MMM d, y').format(expense.date),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.category_outlined,
                      label: expense.category.toUpperCase(),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Paid by ${expense.paidByName}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Participants', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              StreamBuilder<List<ExpenseParticipantModel>>(
                stream: firestore.getExpenseParticipantsStream(expense.id),
                builder: (context, snapshot) {
                  final participants = snapshot.data ?? const <ExpenseParticipantModel>[];
                  final ids = expense.participantUserIds;
                  final toShow = participants.isEmpty
                      ? ids
                          .map((id) => ExpenseParticipantModel(userId: id, fullName: id))
                          .toList()
                      : participants;

                  if (toShow.isEmpty) {
                    return Text(
                      'No participants recorded for this expense.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                    );
                  }

                  return Column(
                    children: toShow.map((p) {
                      final subtitle = _participantSubtitle(expense, p);
                      final displayName = p.fullName.trim().isEmpty ? p.userId : p.fullName.trim();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DarkCard(
                          radius: 18,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.secondaryAccentBlue.withAlpha(55),
                                child: Text(
                                  (displayName.isEmpty ? '?' : displayName[0].toUpperCase()),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(displayName, style: Theme.of(context).textTheme.titleSmall),
                                    if (subtitle != null)
                                      Text(
                                        subtitle,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              if ((expense.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                DarkCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Text(expense.notes!.trim()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _participantSubtitle(ExpenseModel expense, ExpenseParticipantModel p) {
    switch (expense.splitType) {
      case 'exact':
        final cents = p.exactCents;
        return cents == null ? null : 'Exact: ${Formatters.currency(cents / 100)}';
      case 'percentage':
        final bps = p.percentageBps;
        return bps == null ? null : 'Percent: ${(bps / 100).toStringAsFixed(2)}%';
      case 'shares':
        final shares = p.shares;
        return shares == null ? null : 'Shares: $shares';
      case 'equal':
      default:
        return null;
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
