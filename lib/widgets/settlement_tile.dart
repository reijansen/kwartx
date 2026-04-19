import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dark_card.dart';

class SettlementTile extends StatelessWidget {
  const SettlementTile({
    super.key,
    required this.label,
    required this.amount,
    required this.positive,
  });

  final String label;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DarkCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium,
            ),
          ),
          Text(
            amount,
            style: textTheme.titleMedium?.copyWith(
              color: positive ? AppTheme.successGreen : AppTheme.dangerRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
