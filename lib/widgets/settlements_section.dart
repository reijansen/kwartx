import 'package:flutter/material.dart';

import '../roommate/models/settlement_transaction.dart';
import '../roommate/utils/money_utils.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';

class SettlementsSection extends StatelessWidget {
  const SettlementsSection({
    super.key,
    required this.currentUserId,
    required this.userNameById,
    required this.settlements,
  });

  final String currentUserId;
  final Map<String, String> userNameById;
  final List<SettlementTransaction> settlements;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settlements', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        DarkCard(
          radius: 16,
          padding: const EdgeInsets.all(14),
          child: settlements.isEmpty
              ? Text(
                  'All settled up. No unsettled balances right now.',
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
                )
              : Column(
                  children: settlements.map((tx) {
                    final fromName = userNameById[tx.fromUserId] ?? tx.fromUserId;
                    final toName = userNameById[tx.toUserId] ?? tx.toUserId;
                    final isYouDebtor = tx.fromUserId == currentUserId;
                    final isYouCreditor = tx.toUserId == currentUserId;
                    final line = isYouDebtor
                        ? 'You owe $toName'
                        : isYouCreditor
                        ? '$fromName owes you'
                        : '$fromName owes $toName';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              line,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            MoneyUtils.formatCents(tx.amountCents),
                            style: textTheme.bodyMedium?.copyWith(
                              color: isYouDebtor
                                  ? AppTheme.dangerRed
                                  : AppTheme.successGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
