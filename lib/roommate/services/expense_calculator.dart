import '../enums/split_type.dart';
import '../models/expense.dart';
import '../models/expense_participant.dart';
import '../models/expense_share_breakdown.dart';
import '../utils/expense_validation_exception.dart';

class ExpenseCalculator {
  const ExpenseCalculator();

  ExpenseShareBreakdown calculateBreakdown(RoommateExpense expense) {
    _validateBaseExpense(expense);

    final sharesByUser = switch (expense.splitType) {
      SplitType.equal => _computeEqualSplit(
        amountCents: expense.amountCents,
        participants: expense.participants,
      ),
      SplitType.exact => _computeExactSplit(
        amountCents: expense.amountCents,
        participants: expense.participants,
      ),
      SplitType.percentage => _computePercentageSplit(
        amountCents: expense.amountCents,
        participants: expense.participants,
      ),
      SplitType.shares => _computeSharesSplit(
        amountCents: expense.amountCents,
        participants: expense.participants,
      ),
    };

    final payerOwes = sharesByUser[expense.paidByUserId] ?? 0;
    return ExpenseShareBreakdown(
      expenseId: expense.id,
      totalAmountCents: expense.amountCents,
      paidByUserId: expense.paidByUserId,
      sharesByUserId: sharesByUser,
      payerAdvancedCents: expense.amountCents - payerOwes,
    );
  }

  void _validateBaseExpense(RoommateExpense expense) {
    if (expense.id.trim().isEmpty) {
      throw const ExpenseValidationException('Expense id is required.');
    }
    if (expense.title.trim().isEmpty) {
      throw const ExpenseValidationException('Expense title is required.');
    }
    if (expense.amountCents <= 0) {
      throw const ExpenseValidationException(
        'Expense amount must be greater than zero.',
      );
    }
    if (expense.paidByUserId.trim().isEmpty) {
      throw const ExpenseValidationException('paidByUserId is required.');
    }
    if (expense.createdByUserId.trim().isEmpty) {
      throw const ExpenseValidationException('createdByUserId is required.');
    }
    if (expense.participants.isEmpty) {
      throw const ExpenseValidationException('At least one participant is required.');
    }

    final seen = <String>{};
    for (final participant in expense.participants) {
      final userId = participant.userId.trim();
      if (userId.isEmpty) {
        throw const ExpenseValidationException(
          'Participant userId cannot be empty.',
        );
      }
      if (!seen.add(userId)) {
        throw ExpenseValidationException(
          'Duplicate participant found for userId "$userId".',
        );
      }
    }
  }

  Map<String, int> _computeEqualSplit({
    required int amountCents,
    required List<ExpenseParticipant> participants,
  }) {
    final count = participants.length;
    final base = amountCents ~/ count;
    final remainder = amountCents % count;

    final result = <String, int>{};
    for (var i = 0; i < participants.length; i++) {
      final bonus = i < remainder ? 1 : 0;
      result[participants[i].userId] = base + bonus;
    }
    return result;
  }

  Map<String, int> _computeExactSplit({
    required int amountCents,
    required List<ExpenseParticipant> participants,
  }) {
    var total = 0;
    final result = <String, int>{};
    for (final participant in participants) {
      final value = participant.exactAmountCents;
      if (value == null || value < 0) {
        throw ExpenseValidationException(
          'Exact split requires non-negative exactAmountCents for ${participant.userId}.',
        );
      }
      total += value;
      result[participant.userId] = value;
    }
    if (total != amountCents) {
      throw ExpenseValidationException(
        'Exact split total ($total) must equal expense amount ($amountCents).',
      );
    }
    return result;
  }

  Map<String, int> _computePercentageSplit({
    required int amountCents,
    required List<ExpenseParticipant> participants,
  }) {
    const fullPercentBps = 10000;
    var totalBps = 0;
    final weights = <String, int>{};
    for (final participant in participants) {
      final basisPoints = participant.percentageBasisPoints;
      if (basisPoints == null || basisPoints < 0) {
        throw ExpenseValidationException(
          'Percentage split requires non-negative percentageBasisPoints for ${participant.userId}.',
        );
      }
      totalBps += basisPoints;
      weights[participant.userId] = basisPoints;
    }
    if (totalBps != fullPercentBps) {
      throw ExpenseValidationException(
        'Percentage split must total 10000 basis points (100%).',
      );
    }
    return _allocateProportional(
      amountCents: amountCents,
      weightsByUserId: weights,
      denominator: fullPercentBps,
      participantOrder: participants.map((it) => it.userId).toList(),
    );
  }

  Map<String, int> _computeSharesSplit({
    required int amountCents,
    required List<ExpenseParticipant> participants,
  }) {
    var totalShares = 0;
    final weights = <String, int>{};
    for (final participant in participants) {
      final shareValue = participant.shares;
      if (shareValue == null || shareValue <= 0) {
        throw ExpenseValidationException(
          'Shares split requires positive shares for ${participant.userId}.',
        );
      }
      totalShares += shareValue;
      weights[participant.userId] = shareValue;
    }
    return _allocateProportional(
      amountCents: amountCents,
      weightsByUserId: weights,
      denominator: totalShares,
      participantOrder: participants.map((it) => it.userId).toList(),
    );
  }

  Map<String, int> _allocateProportional({
    required int amountCents,
    required Map<String, int> weightsByUserId,
    required int denominator,
    required List<String> participantOrder,
  }) {
    final centsByUser = <String, int>{};
    final remainderTuples = <_RemainderTuple>[];

    var allocated = 0;
    for (var i = 0; i < participantOrder.length; i++) {
      final userId = participantOrder[i];
      final weight = weightsByUserId[userId] ?? 0;
      final numerator = amountCents * weight;
      final base = numerator ~/ denominator;
      final remainder = numerator % denominator;
      centsByUser[userId] = base;
      allocated += base;
      remainderTuples.add(
        _RemainderTuple(userId: userId, remainder: remainder, order: i),
      );
    }

    var remaining = amountCents - allocated;
    remainderTuples.sort((a, b) {
      final byRemainder = b.remainder.compareTo(a.remainder);
      if (byRemainder != 0) {
        return byRemainder;
      }
      return a.order.compareTo(b.order);
    });

    for (final tuple in remainderTuples) {
      if (remaining <= 0) {
        break;
      }
      centsByUser[tuple.userId] = (centsByUser[tuple.userId] ?? 0) + 1;
      remaining -= 1;
    }

    return centsByUser;
  }
}

class _RemainderTuple {
  const _RemainderTuple({
    required this.userId,
    required this.remainder,
    required this.order,
  });

  final String userId;
  final int remainder;
  final int order;
}
