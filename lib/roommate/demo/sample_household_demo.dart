import '../enums/expense_category.dart';
import '../enums/split_type.dart';
import '../models/expense.dart';
import '../models/expense_participant.dart';
import '../models/household_member.dart';
import '../services/balance_aggregator.dart';
import '../services/debt_simplifier.dart';
import '../utils/money_utils.dart';

class SampleHouseholdDemo {
  static const String householdId = 'household_demo_kwartx';
  static const String uAna = 'ana';
  static const String uMiguel = 'miguel';
  static const String uCarlo = 'carlo';
  static const String uJansen = 'jansen';

  static List<HouseholdMember> members() {
    return const [
      HouseholdMember(
        id: uAna,
        displayName: 'Ana',
        email: 'ana@kwartx.app',
        isCurrentUser: true,
      ),
      HouseholdMember(
        id: uMiguel,
        displayName: 'Miguel',
        email: 'miguel@kwartx.app',
      ),
      HouseholdMember(
        id: uCarlo,
        displayName: 'Carlo',
        email: 'carlo@kwartx.app',
      ),
      HouseholdMember(
        id: uJansen,
        displayName: 'Jansen',
        email: 'jansen@kwartx.app',
      ),
    ];
  }

  static List<RoommateExpense> expenses() {
    const all = [
      ExpenseParticipant(userId: uAna),
      ExpenseParticipant(userId: uMiguel),
      ExpenseParticipant(userId: uCarlo),
      ExpenseParticipant(userId: uJansen),
    ];
    return [
      RoommateExpense(
        id: 'exp_rent',
        householdId: householdId,
        title: 'Apartment Rent',
        amountCents: 48000,
        paidByUserId: uAna,
        createdByUserId: uAna,
        date: DateTime(2026, 4, 1),
        category: ExpenseCategory.rent,
        splitType: SplitType.equal,
        participants: all,
      ),
      RoommateExpense(
        id: 'exp_electricity',
        householdId: householdId,
        title: 'Electricity Bill',
        amountCents: 3600,
        paidByUserId: uMiguel,
        createdByUserId: uMiguel,
        date: DateTime(2026, 4, 5),
        category: ExpenseCategory.electricity,
        splitType: SplitType.equal,
        participants: all,
      ),
      RoommateExpense(
        id: 'exp_grocery',
        householdId: householdId,
        title: 'Groceries',
        amountCents: 2500,
        paidByUserId: uCarlo,
        createdByUserId: uCarlo,
        date: DateTime(2026, 4, 8),
        category: ExpenseCategory.groceries,
        splitType: SplitType.percentage,
        participants: const [
          ExpenseParticipant(userId: uAna, percentageBasisPoints: 3000),
          ExpenseParticipant(userId: uMiguel, percentageBasisPoints: 3000),
          ExpenseParticipant(userId: uCarlo, percentageBasisPoints: 2000),
          ExpenseParticipant(userId: uJansen, percentageBasisPoints: 2000),
        ],
      ),
      RoommateExpense(
        id: 'exp_water',
        householdId: householdId,
        title: 'Water Bill',
        amountCents: 1400,
        paidByUserId: uJansen,
        createdByUserId: uJansen,
        date: DateTime(2026, 4, 10),
        category: ExpenseCategory.water,
        splitType: SplitType.shares,
        participants: const [
          ExpenseParticipant(userId: uAna, shares: 1),
          ExpenseParticipant(userId: uMiguel, shares: 1),
          ExpenseParticipant(userId: uCarlo, shares: 1),
          ExpenseParticipant(userId: uJansen, shares: 1),
        ],
      ),
      RoommateExpense(
        id: 'exp_wifi_duo',
        householdId: householdId,
        title: 'WiFi Upgrade',
        amountCents: 1000,
        paidByUserId: uMiguel,
        createdByUserId: uMiguel,
        date: DateTime(2026, 4, 12),
        category: ExpenseCategory.wifi,
        splitType: SplitType.exact,
        participants: const [
          ExpenseParticipant(userId: uMiguel, exactAmountCents: 400),
          ExpenseParticipant(userId: uAna, exactAmountCents: 600),
        ],
      ),
    ];
  }

  static void printConsoleSummary() {
    final aggregator = BalanceAggregator();
    final balances = aggregator.aggregate(members: members(), expenses: expenses());
    final settlements = const DebtSimplifier().simplify(balances);

    // Expected final net balances:
    // Ana: +19600
    // Miguel: -6400
    // Carlo: -12600
    // Jansen: -600
    for (final balance in balances) {
      // ignore: avoid_print
      print(
        '${balance.displayName}: paid ${MoneyUtils.formatCents(balance.totalPaidCents)} | '
        'owed ${MoneyUtils.formatCents(balance.totalOwedCents)} | '
        'net ${MoneyUtils.formatCents(balance.netBalanceCents)}',
      );
    }

    // Expected simplified settlements:
    // Carlo -> Ana: ₱126
    // Miguel -> Ana: ₱64
    // Jansen -> Ana: ₱6
    for (final settlement in settlements) {
      // ignore: avoid_print
      print(
        '${settlement.fromUserId} pays ${settlement.toUserId} '
        '${MoneyUtils.formatCents(settlement.amountCents)}',
      );
    }
  }
}
