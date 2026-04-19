import '../models/balance_summary.dart';
import '../models/expense.dart';
import '../models/household_member.dart';
import '../models/settlement_transaction.dart';

class RoommateDashboardState {
  const RoommateDashboardState({
    this.isLoading = true,
    this.errorMessage,
    this.members = const [],
    this.expenses = const [],
    this.balances = const [],
    this.settlements = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final List<HouseholdMember> members;
  final List<RoommateExpense> expenses;
  final List<BalanceSummary> balances;
  final List<SettlementTransaction> settlements;

  bool get isEmpty => expenses.isEmpty;

  RoommateDashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<HouseholdMember>? members,
    List<RoommateExpense>? expenses,
    List<BalanceSummary>? balances,
    List<SettlementTransaction>? settlements,
  }) {
    return RoommateDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      balances: balances ?? this.balances,
      settlements: settlements ?? this.settlements,
    );
  }
}
