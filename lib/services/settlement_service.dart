import '../models/expense_model.dart';
import '../models/expense_participant_model.dart';
import '../models/roommate_model.dart';
import '../models/settlement_view_model.dart';
import '../models/user_profile_model.dart';

class BalanceBucket {
  const BalanceBucket({
    required this.userId,
    required this.fullName,
    required this.paidCents,
    required this.owedCents,
  });

  final String userId;
  final String fullName;
  final int paidCents;
  final int owedCents;

  int get netCents => paidCents - owedCents;
  int get youOweCents => netCents < 0 ? -netCents : 0;
  int get youAreOwedCents => netCents > 0 ? netCents : 0;
}

class SettlementService {
  const SettlementService();

  List<BalanceBucket> computeBalances({
    required UserProfileModel currentUser,
    required List<RoommateModel> roommates,
    required List<ExpenseModel> expenses,
    required Map<String, List<ExpenseParticipantModel>> participantsByExpenseId,
  }) {
    final nameById = <String, String>{
      currentUser.id: currentUser.fullName,
      for (final roommate in roommates)
        if (roommate.linkedUid != null && roommate.linkedUid!.isNotEmpty)
          roommate.linkedUid!: roommate.displayName,
    };

    final paid = <String, int>{};
    final owed = <String, int>{};

    for (final expense in expenses) {
      paid[expense.paidByUserId] = (paid[expense.paidByUserId] ?? 0) + expense.amountCents;
      final expenseParticipants = participantsByExpenseId[expense.id] ?? const [];
      final shares = _computeShares(
        expense: expense,
        participants: expenseParticipants,
      );
      shares.forEach((userId, value) {
        owed[userId] = (owed[userId] ?? 0) + value;
      });
    }

    final allIds = <String>{...nameById.keys, ...paid.keys, ...owed.keys};
    final buckets = allIds.map((id) {
      return BalanceBucket(
        userId: id,
        fullName: nameById[id] ?? id,
        paidCents: paid[id] ?? 0,
        owedCents: owed[id] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return buckets;
  }

  List<SettlementViewModel> simplifyDebts(List<BalanceBucket> balances) {
    final creditors = balances
        .where((bucket) => bucket.netCents > 0)
        .map((bucket) => _Node(
              userId: bucket.userId,
              fullName: bucket.fullName,
              cents: bucket.netCents,
            ))
        .toList()
      ..sort((a, b) => b.cents.compareTo(a.cents));

    final debtors = balances
        .where((bucket) => bucket.netCents < 0)
        .map((bucket) => _Node(
              userId: bucket.userId,
              fullName: bucket.fullName,
              cents: -bucket.netCents,
            ))
        .toList()
      ..sort((a, b) => b.cents.compareTo(a.cents));

    final settlements = <SettlementViewModel>[];
    var d = 0;
    var c = 0;
    while (d < debtors.length && c < creditors.length) {
      final debtor = debtors[d];
      final creditor = creditors[c];
      final transfer = debtor.cents < creditor.cents ? debtor.cents : creditor.cents;
      if (transfer > 0) {
        settlements.add(
          SettlementViewModel(
            fromUserId: debtor.userId,
            fromName: debtor.fullName,
            toUserId: creditor.userId,
            toName: creditor.fullName,
            amountCents: transfer,
          ),
        );
      }
      debtor.cents -= transfer;
      creditor.cents -= transfer;
      if (debtor.cents <= 1) {
        d += 1;
      }
      if (creditor.cents <= 1) {
        c += 1;
      }
    }

    return settlements;
  }

  Map<String, int> _computeShares({
    required ExpenseModel expense,
    required List<ExpenseParticipantModel> participants,
  }) {
    final participantIds = expense.participantUserIds;
    if (participantIds.isEmpty) {
      return {expense.paidByUserId: expense.amountCents};
    }

    switch (expense.splitType) {
      case 'exact':
        final map = <String, int>{};
        var total = 0;
        for (final p in participants) {
          final val = p.exactCents ?? 0;
          map[p.userId] = val;
          total += val;
        }
        if (total == expense.amountCents && map.isNotEmpty) {
          return map;
        }
        return _equalSplit(expense.amountCents, participantIds);
      case 'percentage':
        final map = <String, int>{};
        var allocated = 0;
        final ordered = participants
            .where((p) => (p.percentageBps ?? 0) > 0)
            .toList();
        for (final p in ordered) {
          final share = (expense.amountCents * (p.percentageBps ?? 0)) ~/ 10000;
          map[p.userId] = share;
          allocated += share;
        }
        final remainder = expense.amountCents - allocated;
        if (remainder > 0 && ordered.isNotEmpty) {
          map[ordered.first.userId] = (map[ordered.first.userId] ?? 0) + remainder;
        }
        return map.isEmpty ? _equalSplit(expense.amountCents, participantIds) : map;
      case 'shares':
        final valid = participants.where((p) => (p.shares ?? 0) > 0).toList();
        final totalShares = valid.fold<int>(0, (sum, p) => sum + (p.shares ?? 0));
        if (totalShares <= 0) {
          return _equalSplit(expense.amountCents, participantIds);
        }
        final map = <String, int>{};
        var allocated = 0;
        for (final p in valid) {
          final share = (expense.amountCents * (p.shares ?? 0)) ~/ totalShares;
          map[p.userId] = share;
          allocated += share;
        }
        final remainder = expense.amountCents - allocated;
        if (remainder > 0 && valid.isNotEmpty) {
          map[valid.first.userId] = (map[valid.first.userId] ?? 0) + remainder;
        }
        return map;
      case 'equal':
      default:
        return _equalSplit(expense.amountCents, participantIds);
    }
  }

  Map<String, int> _equalSplit(int amountCents, List<String> participantIds) {
    final base = amountCents ~/ participantIds.length;
    final remainder = amountCents % participantIds.length;
    final map = <String, int>{};
    for (var i = 0; i < participantIds.length; i++) {
      map[participantIds[i]] = base + (i < remainder ? 1 : 0);
    }
    return map;
  }
}

class _Node {
  _Node({
    required this.userId,
    required this.fullName,
    required this.cents,
  });

  final String userId;
  final String fullName;
  int cents;
}
