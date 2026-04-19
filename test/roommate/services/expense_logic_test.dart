import 'package:flutter_test/flutter_test.dart';
import 'package:kwartx/roommate/enums/expense_category.dart';
import 'package:kwartx/roommate/enums/split_type.dart';
import 'package:kwartx/roommate/models/balance_summary.dart';
import 'package:kwartx/roommate/models/expense.dart';
import 'package:kwartx/roommate/models/expense_participant.dart';
import 'package:kwartx/roommate/models/household_member.dart';
import 'package:kwartx/roommate/services/balance_aggregator.dart';
import 'package:kwartx/roommate/services/debt_simplifier.dart';
import 'package:kwartx/roommate/services/expense_calculator.dart';

void main() {
  group('ExpenseCalculator', () {
    const calculator = ExpenseCalculator();

    test('equal split', () {
      final expense = _expense(
        id: 'e1',
        amountCents: 1000,
        paidBy: 'u1',
        splitType: SplitType.equal,
        participants: const [
          ExpenseParticipant(userId: 'u1'),
          ExpenseParticipant(userId: 'u2'),
          ExpenseParticipant(userId: 'u3'),
          ExpenseParticipant(userId: 'u4'),
        ],
      );

      final breakdown = calculator.calculateBreakdown(expense);
      expect(breakdown.sharesByUserId['u1'], 250);
      expect(breakdown.sharesByUserId['u2'], 250);
      expect(breakdown.sharesByUserId['u3'], 250);
      expect(breakdown.sharesByUserId['u4'], 250);
      expect(breakdown.payerAdvancedCents, 750);
    });

    test('uneven equal split with remainder cents', () {
      final expense = _expense(
        id: 'e2',
        amountCents: 1001,
        paidBy: 'u1',
        splitType: SplitType.equal,
        participants: const [
          ExpenseParticipant(userId: 'u1'),
          ExpenseParticipant(userId: 'u2'),
          ExpenseParticipant(userId: 'u3'),
        ],
      );

      final breakdown = calculator.calculateBreakdown(expense);
      expect(breakdown.sharesByUserId['u1'], 334);
      expect(breakdown.sharesByUserId['u2'], 334);
      expect(breakdown.sharesByUserId['u3'], 333);
    });

    test('exact split', () {
      final expense = _expense(
        id: 'e3',
        amountCents: 2500,
        paidBy: 'u2',
        splitType: SplitType.exact,
        participants: const [
          ExpenseParticipant(userId: 'u1', exactAmountCents: 1000),
          ExpenseParticipant(userId: 'u2', exactAmountCents: 900),
          ExpenseParticipant(userId: 'u3', exactAmountCents: 600),
        ],
      );

      final breakdown = calculator.calculateBreakdown(expense);
      expect(breakdown.sharesByUserId['u1'], 1000);
      expect(breakdown.sharesByUserId['u2'], 900);
      expect(breakdown.sharesByUserId['u3'], 600);
    });

    test('percentage split', () {
      final expense = _expense(
        id: 'e4',
        amountCents: 1000,
        paidBy: 'u3',
        splitType: SplitType.percentage,
        participants: const [
          ExpenseParticipant(userId: 'u1', percentageBasisPoints: 5000),
          ExpenseParticipant(userId: 'u2', percentageBasisPoints: 3000),
          ExpenseParticipant(userId: 'u3', percentageBasisPoints: 2000),
        ],
      );

      final breakdown = calculator.calculateBreakdown(expense);
      expect(breakdown.sharesByUserId['u1'], 500);
      expect(breakdown.sharesByUserId['u2'], 300);
      expect(breakdown.sharesByUserId['u3'], 200);
    });

    test('shares split', () {
      final expense = _expense(
        id: 'e5',
        amountCents: 1000,
        paidBy: 'u1',
        splitType: SplitType.shares,
        participants: const [
          ExpenseParticipant(userId: 'u1', shares: 3),
          ExpenseParticipant(userId: 'u2', shares: 2),
          ExpenseParticipant(userId: 'u3', shares: 1),
        ],
      );

      final breakdown = calculator.calculateBreakdown(expense);
      expect(breakdown.sharesByUserId['u1'], 500);
      expect(breakdown.sharesByUserId['u2'], 333);
      expect(breakdown.sharesByUserId['u3'], 167);
    });
  });

  group('Balance and settlement', () {
    test('multiple expenses across different payers and subset participants', () {
      final members = const [
        HouseholdMember(id: 'u1', displayName: 'Ana', email: 'ana@test.com'),
        HouseholdMember(id: 'u2', displayName: 'Miguel', email: 'mig@test.com'),
        HouseholdMember(id: 'u3', displayName: 'Carlo', email: 'car@test.com'),
        HouseholdMember(id: 'u4', displayName: 'Jansen', email: 'jan@test.com'),
      ];
      final expenses = [
        _expense(
          id: 'm1',
          amountCents: 48000,
          paidBy: 'u1',
          splitType: SplitType.equal,
          participants: const [
            ExpenseParticipant(userId: 'u1'),
            ExpenseParticipant(userId: 'u2'),
            ExpenseParticipant(userId: 'u3'),
            ExpenseParticipant(userId: 'u4'),
          ],
        ),
        _expense(
          id: 'm2',
          amountCents: 1000,
          paidBy: 'u2',
          splitType: SplitType.exact,
          participants: const [
            ExpenseParticipant(userId: 'u1', exactAmountCents: 600),
            ExpenseParticipant(userId: 'u2', exactAmountCents: 400),
          ],
        ),
      ];

      final balances = BalanceAggregator().aggregate(
        members: members,
        expenses: expenses,
      );

      final byId = {for (final balance in balances) balance.userId: balance};
      expect(byId['u3']!.totalOwedCents, 12000);
      expect(byId['u3']!.totalPaidCents, 0);
      expect(byId['u4']!.totalOwedCents, 12000);
      expect(byId['u2']!.totalPaidCents, 1000);
      expect(byId['u2']!.totalOwedCents, 12400);
    });

    test('settlement simplification with at least 4 roommates', () {
      final balances = const [
        BalanceSummary(
          userId: 'u1',
          displayName: 'Ana',
          totalPaidCents: 3000,
          totalOwedCents: 0,
        ),
        BalanceSummary(
          userId: 'u2',
          displayName: 'Miguel',
          totalPaidCents: 0,
          totalOwedCents: 1100,
        ),
        BalanceSummary(
          userId: 'u3',
          displayName: 'Carlo',
          totalPaidCents: 0,
          totalOwedCents: 900,
        ),
        BalanceSummary(
          userId: 'u4',
          displayName: 'Jansen',
          totalPaidCents: 0,
          totalOwedCents: 1000,
        ),
      ];

      final settlements = const DebtSimplifier().simplify(balances);
      final totalSettled = settlements.fold<int>(
        0,
        (sum, tx) => sum + tx.amountCents,
      );

      expect(totalSettled, 3000);
      expect(settlements.every((tx) => tx.toUserId == 'u1'), isTrue);
    });
  });
}

RoommateExpense _expense({
  required String id,
  required int amountCents,
  required String paidBy,
  required SplitType splitType,
  required List<ExpenseParticipant> participants,
}) {
  return RoommateExpense(
    id: id,
    householdId: 'h1',
    title: 'Expense $id',
    amountCents: amountCents,
    paidByUserId: paidBy,
    createdByUserId: paidBy,
    date: DateTime(2026, 1, 1),
    category: ExpenseCategory.misc,
    splitType: splitType,
    participants: participants,
  );
}
