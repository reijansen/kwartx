import '../models/balance_summary.dart';
import '../models/settlement_transaction.dart';

class DebtSimplifier {
  const DebtSimplifier();

  List<SettlementTransaction> simplify(
    List<BalanceSummary> balances, {
    int epsilonCents = 1,
  }) {
    final creditors = balances
        .where((it) => it.netBalanceCents > epsilonCents)
        .map((it) => _BalanceNode(userId: it.userId, amountCents: it.netBalanceCents))
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    final debtors = balances
        .where((it) => it.netBalanceCents < -epsilonCents)
        .map((it) => _BalanceNode(userId: it.userId, amountCents: -it.netBalanceCents))
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    final settlements = <SettlementTransaction>[];
    var i = 0;
    var j = 0;

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];
      final transfer = debtor.amountCents < creditor.amountCents
          ? debtor.amountCents
          : creditor.amountCents;

      if (transfer > 0) {
        settlements.add(
          SettlementTransaction(
            fromUserId: debtor.userId,
            toUserId: creditor.userId,
            amountCents: transfer,
          ),
        );
        debtor.amountCents -= transfer;
        creditor.amountCents -= transfer;
      }

      if (debtor.amountCents <= epsilonCents) {
        i += 1;
      }
      if (creditor.amountCents <= epsilonCents) {
        j += 1;
      }
    }

    return settlements;
  }
}

class _BalanceNode {
  _BalanceNode({required this.userId, required this.amountCents});

  final String userId;
  int amountCents;
}
