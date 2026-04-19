import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/household_member.dart';
import '../repositories/expense_repository.dart';
import '../repositories/household_repository.dart';
import '../services/balance_aggregator.dart';
import '../services/debt_simplifier.dart';
import 'roommate_dashboard_state.dart';

class RoommateDashboardController extends ChangeNotifier {
  RoommateDashboardController({
    required HouseholdRepository householdRepository,
    required ExpenseRepository expenseRepository,
    BalanceAggregator? balanceAggregator,
    DebtSimplifier? debtSimplifier,
  }) : _householdRepository = householdRepository,
       _expenseRepository = expenseRepository,
       _balanceAggregator = balanceAggregator ?? BalanceAggregator(),
       _debtSimplifier = debtSimplifier ?? const DebtSimplifier();

  final HouseholdRepository _householdRepository;
  final ExpenseRepository _expenseRepository;
  final BalanceAggregator _balanceAggregator;
  final DebtSimplifier _debtSimplifier;

  RoommateDashboardState _state = const RoommateDashboardState();
  RoommateDashboardState get state => _state;

  StreamSubscription<List<HouseholdMember>>? _membersSub;
  StreamSubscription<List<RoommateExpense>>? _expensesSub;

  String? _householdId;

  void start(String householdId) {
    if (_householdId == householdId) {
      return;
    }
    _householdId = householdId;
    _membersSub?.cancel();
    _expensesSub?.cancel();
    _state = const RoommateDashboardState(isLoading: true);
    notifyListeners();

    _membersSub = _householdRepository
        .watchHouseholdMembers(householdId)
        .listen((members) {
          _state = _state.copyWith(members: members, isLoading: false);
          _recompute();
        }, onError: (error) {
          _state = _state.copyWith(
            isLoading: false,
            errorMessage: error.toString(),
          );
          notifyListeners();
        });

    _expensesSub = _expenseRepository.watchExpenses(householdId).listen((expenses) {
      _state = _state.copyWith(expenses: expenses, isLoading: false);
      _recompute();
    }, onError: (error) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      notifyListeners();
    });
  }

  void _recompute() {
    final balances = _balanceAggregator.aggregate(
      members: _state.members,
      expenses: _state.expenses,
    );
    final settlements = _debtSimplifier.simplify(balances);

    _state = _state.copyWith(
      balances: balances,
      settlements: settlements,
      errorMessage: null,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _expensesSub?.cancel();
    super.dispose();
  }
}
