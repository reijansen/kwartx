import 'package:flutter/material.dart';

import '../roommate/utils/money_utils.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';

class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({
    super.key,
    required this.netBalanceCents,
    required this.monthTotalCents,
    required this.householdTotalCents,
    required this.topPayerLabel,
  });

  final int netBalanceCents;
  final int monthTotalCents;
  final int householdTotalCents;
  final String topPayerLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOwed = netBalanceCents > 0;
    final isOwing = netBalanceCents < 0;

    final headline = isOwing
        ? 'You owe'
        : isOwed
        ? 'You are owed'
        : 'All settled up';
    final amountText = isOwing || isOwed
        ? MoneyUtils.formatCents(netBalanceCents.abs())
        : MoneyUtils.formatCents(0);
    final accentColor = isOwing
        ? AppTheme.dangerRed
        : isOwed
        ? AppTheme.successGreen
        : AppTheme.secondaryAccentBlue;

    return DarkCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            amountText,
            style: textTheme.headlineMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                label: 'This month',
                value: MoneyUtils.formatCents(monthTotalCents),
              ),
              _StatPill(
                label: 'Household total',
                value: MoneyUtils.formatCents(householdTotalCents),
              ),
              _StatPill(label: 'Top payer', value: topPayerLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.navOverlay,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.glowOutlineBlue.withAlpha(90)),
      ),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
