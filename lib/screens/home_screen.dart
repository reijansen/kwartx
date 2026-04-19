import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../models/expense_model.dart';
import '../models/roommate_model.dart';
import '../roommate/enums/expense_category.dart';
import '../roommate/enums/split_type.dart';
import '../roommate/models/expense.dart';
import '../roommate/models/expense_participant.dart';
import '../roommate/models/household_member.dart';
import '../roommate/models/settlement_transaction.dart';
import '../roommate/services/balance_aggregator.dart';
import '../roommate/services/debt_simplifier.dart';
import '../roommate/utils/money_utils.dart';
import '../services/auth_service.dart';
import '../services/expense_report_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/dark_card.dart';
import '../widgets/roommate_context_card.dart';
import '../widgets/settlements_section.dart';
import 'expense_form_screen.dart';
import 'invite_roommate_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final BalanceAggregator _balanceAggregator = BalanceAggregator();
  final DebtSimplifier _debtSimplifier = const DebtSimplifier();
  final DateFormat _dateFormatter = DateFormat('MMM d, y');
  final TextEditingController _searchController = TextEditingController();

  bool _isSigningOut = false;
  String _searchQuery = '';
  String _selectedCategory = _allCategoriesKey;
  _ExpenseSortOption _sortOption = _ExpenseSortOption.newestFirst;
  _ExpenseDateFilter _dateFilter = _ExpenseDateFilter.allTime;
  static const String _allCategoriesKey = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final nextValue = _searchController.text.trim();
    if (_searchQuery == nextValue) {
      return;
    }
    setState(() {
      _searchQuery = nextValue;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  String _safeLabel(String? raw, String fallback) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  int _safeSplitCount(int value) => value <= 0 ? 1 : value;

  double _amountPerPerson(ExpenseModel expense) {
    return expense.amount / _safeSplitCount(expense.splitCount);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _matchesDateFilter(ExpenseModel expense, _ExpenseDateFilter filter) {
    if (filter == _ExpenseDateFilter.allTime) {
      return true;
    }
    final now = DateTime.now();
    if (filter == _ExpenseDateFilter.thisMonth) {
      return expense.createdAt.year == now.year &&
          expense.createdAt.month == now.month;
    }
    final weekStart = _startOfWeek(now);
    final expenseDate = DateTime(
      expense.createdAt.year,
      expense.createdAt.month,
      expense.createdAt.day,
    );
    return !expenseDate.isBefore(weekStart);
  }

  List<String> _deriveCategories(List<ExpenseModel> expenses) {
    final categories =
        expenses
            .map(
              (expense) =>
                  _safeLabel(expense.category, AppConstants.defaultCategory),
            )
            .followedBy(AppConstants.expenseCategories)
            .toSet()
            .toList()
          ..sort();
    return [_allCategoriesKey, ...categories];
  }

  List<ExpenseModel> _applyFiltersAndSort(
    List<ExpenseModel> source, {
    required String categoryFilter,
  }) {
    final query = _searchQuery.toLowerCase();
    final filtered = source.where((expense) {
      final category = _safeLabel(
        expense.category,
        AppConstants.defaultCategory,
      );
      final paidBy = _safeLabel(expense.paidBy, AppConstants.unknownPayer);
      final title = expense.title.trim();

      if (categoryFilter != _allCategoriesKey && category != categoryFilter) {
        return false;
      }
      if (!_matchesDateFilter(expense, _dateFilter)) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      return title.toLowerCase().contains(query) ||
          paidBy.toLowerCase().contains(query) ||
          category.toLowerCase().contains(query);
    }).toList();

    switch (_sortOption) {
      case _ExpenseSortOption.newestFirst:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _ExpenseSortOption.oldestFirst:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _ExpenseSortOption.highestAmount:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _ExpenseSortOption.lowestAmount:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return filtered;
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != _allCategoriesKey ||
        _dateFilter != _ExpenseDateFilter.allTime ||
        _sortOption != _ExpenseSortOption.newestFirst;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = _allCategoriesKey;
      _dateFilter = _ExpenseDateFilter.allTime;
      _sortOption = _ExpenseSortOption.newestFirst;
    });
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showAppConfirmationDialog(
      context,
      title: 'Sign out',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Sign out',
    );
    if (!shouldSignOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.authService.signOut();
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Signed out successfully.',
        type: AppFeedbackType.info,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(
          error,
          fallback: 'Unable to sign out. Please try again.',
        ),
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _openExpenseForm({
    required String title,
    ExpenseModel? expense,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ExpenseFormScreen(title: title, existingExpense: expense),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetTween = Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          );
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position: animation.drive(offsetTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  Future<bool> _confirmDelete(ExpenseModel expense) {
    return showAppConfirmationDialog(
      context,
      title: 'Delete Expense',
      message: 'Delete "${expense.title}" permanently?',
      confirmLabel: 'Delete',
      isDanger: true,
    );
  }

  Future<void> _openReport(List<ExpenseModel> expenses) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReportScreen(expenses: expenses),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  Future<void> _openInvites() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const InviteRoommateScreen()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(authService: widget.authService),
      ),
    );
  }

  Future<void> _onMenuSelected(_HomeMenuAction action) async {
    switch (action) {
      case _HomeMenuAction.profile:
        await _openProfile();
        break;
      case _HomeMenuAction.invites:
        await _openInvites();
        break;
      case _HomeMenuAction.logout:
        if (_isSigningOut) {
          return;
        }
        await _handleSignOut();
        break;
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    try {
      await _firestoreService.deleteExpense(expense.id);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Expense deleted.',
        type: AppFeedbackType.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(
          error,
          fallback: 'Failed to delete expense.',
        ),
        type: AppFeedbackType.error,
      );
    }
  }

  _DashboardSummary _buildSummary(List<ExpenseModel> expenses) {
    final report = ExpenseReportService.buildReport(
      expenses,
      scope: ReportScope.allTime,
    );

    return _DashboardSummary(
      totalAmount: report.totalExpenses,
      totalCount: report.totalEntries,
      averageAmount: report.averageExpense,
      monthAmount: report.thisMonthTotal,
      monthCount: ExpenseReportService.filterByScope(
        expenses,
        scope: ReportScope.thisMonth,
      ).length,
      payerTotals: report.payerTotals,
      categoryTotals: report.categoryTotals,
    );
  }

  List<HouseholdMember> _buildHouseholdMembers({
    required String uid,
    required String email,
    required List<RoommateModel> roommates,
  }) {
    final members = <HouseholdMember>[
      HouseholdMember(
        id: uid,
        displayName: _safeLabel(
          widget.authService.currentUser?.displayName,
          email,
        ),
        email: email,
        isCurrentUser: true,
      ),
    ];
    for (final roommate in roommates) {
      final roommateId = (roommate.linkedUid ?? roommate.id).trim();
      if (roommateId.isEmpty || roommateId == uid) {
        continue;
      }
      members.add(
        HouseholdMember(
          id: roommateId,
          displayName: roommate.displayName,
          email: roommate.email,
        ),
      );
    }
    return members;
  }

  List<RoommateExpense> _mapLegacyExpensesToDomain({
    required List<ExpenseModel> expenses,
    required List<HouseholdMember> members,
    required String currentUserId,
  }) {
    if (members.isEmpty) {
      return const [];
    }

    final membersByLabel = <String, HouseholdMember>{};
    for (final member in members) {
      membersByLabel[member.displayName.toLowerCase()] = member;
      membersByLabel[member.email.toLowerCase()] = member;
    }

    return expenses.map((expense) {
      final payerMember =
          membersByLabel[expense.paidBy.trim().toLowerCase()] ??
          members.firstWhere(
            (member) => member.id == currentUserId,
            orElse: () => members.first,
          );

      final participantCount = expense.splitCount.clamp(1, members.length);
      final participants = members.take(participantCount).map((member) {
        return ExpenseParticipant(userId: member.id);
      }).toList();

      if (!participants.any((participant) => participant.userId == payerMember.id)) {
        participants[0] = ExpenseParticipant(userId: payerMember.id);
      }

      return RoommateExpense(
        id: expense.id,
        householdId: 'legacy_household',
        title: expense.title,
        amountCents: MoneyUtils.toCents(expense.amount),
        paidByUserId: payerMember.id,
        createdByUserId: currentUserId,
        date: expense.createdAt,
        category: ExpenseCategory.misc,
        splitType: SplitType.equal,
        participants: participants,
        notes: null,
      );
    }).toList();
  }

  List<SettlementTransaction> _buildSettlements({
    required List<ExpenseModel> expenses,
    required List<HouseholdMember> members,
    required String currentUserId,
  }) {
    final domainExpenses = _mapLegacyExpensesToDomain(
      expenses: expenses,
      members: members,
      currentUserId: currentUserId,
    );
    final balances = _balanceAggregator.aggregate(
      members: members,
      expenses: domainExpenses,
    );
    return _debtSimplifier.simplify(balances);
  }

  int _computeCurrentUserNetBalanceCents({
    required List<ExpenseModel> expenses,
    required List<HouseholdMember> members,
    required String currentUserId,
  }) {
    final domainExpenses = _mapLegacyExpensesToDomain(
      expenses: expenses,
      members: members,
      currentUserId: currentUserId,
    );
    final balances = _balanceAggregator.aggregate(
      members: members,
      expenses: domainExpenses,
    );
    return balances
        .where((balance) => balance.userId == currentUserId)
        .map((it) => it.netBalanceCents)
        .fold<int>(0, (sum, it) => sum + it);
  }

  Widget _buildContent(
    AsyncSnapshot<List<ExpenseModel>> snapshot,
    TextTheme textTheme,
    String uid,
    String email,
    List<RoommateModel> roommates,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: AppLoadingIndicator(size: 26));
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppEmptyState(
            title: 'Unable to load expenses',
            subtitle: 'Check your connection or try refreshing.',
            icon: Icons.cloud_off_rounded,
            actionLabel: 'Retry',
            onActionPressed: () => setState(() {}),
          ),
        ),
      );
    }

    final allExpenses = snapshot.data ?? [];
    final categories = _deriveCategories(allExpenses);
    final effectiveCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : _allCategoriesKey;

    if (effectiveCategory != _selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedCategory = effectiveCategory;
        });
      });
    }

    final expenses = _applyFiltersAndSort(
      allExpenses,
      categoryFilter: effectiveCategory,
    );
    final summary = _buildSummary(expenses);
    final topPayer = summary.payerTotals.isEmpty
        ? null
        : summary.payerTotals.first;
    final members = _buildHouseholdMembers(
      uid: uid,
      email: email,
      roommates: roommates,
    );
    final settlements = _buildSettlements(
      expenses: allExpenses,
      members: members,
      currentUserId: uid,
    );
    final netBalanceCents = _computeCurrentUserNetBalanceCents(
      expenses: allExpenses,
      members: members,
      currentUserId: uid,
    );
    final memberNameById = {
      for (final member in members) member.id: member.displayName,
    };
    final monthCents = MoneyUtils.toCents(summary.monthAmount);
    final totalCents = MoneyUtils.toCents(summary.totalAmount);

    return _DashboardBody(
      textTheme: textTheme,
      currentUserId: uid,
      email: email,
      roommates: roommates,
      searchController: _searchController,
      searchQuery: _searchQuery,
      selectedCategory: effectiveCategory,
      categories: categories,
      sortOption: _sortOption,
      dateFilter: _dateFilter,
      hasActiveFilters: _hasActiveFilters,
      summary: summary,
      topPayer: topPayer,
      allExpenses: allExpenses,
      visibleExpenses: expenses,
      settlements: settlements,
      netBalanceCents: netBalanceCents,
      userNameById: memberNameById,
      monthTotalCents: monthCents,
      householdTotalCents: totalCents,
      dateFormatter: _dateFormatter,
      formatCurrency: Formatters.currency,
      onRefresh: _onRefresh,
      onCategoryChanged: (value) => setState(() => _selectedCategory = value),
      onSortChanged: (value) => setState(() => _sortOption = value),
      onDateFilterChanged: (value) => setState(() => _dateFilter = value),
      onResetFilters: _resetFilters,
      onAddExpense: () => _openExpenseForm(title: 'Add Expense'),
      onSplitBill: () => _openExpenseForm(title: 'Split Bill'),
      onSummaryTap: () => _openReport(allExpenses),
      onInviteRoommates: _openInvites,
      onEditExpense: (expense) =>
          _openExpenseForm(title: 'Edit Expense', expense: expense),
      onDeleteExpense: _deleteExpense,
      onConfirmDelete: _confirmDelete,
      amountPerPerson: _amountPerPerson,
      safeLabel: _safeLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = widget.authService.currentUser;
    final uid = user?.uid;
    final email = user?.email ?? 'user@kwartx.app';

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
          child: const Center(
            child: AppEmptyState(
              title: 'Session unavailable',
              subtitle: 'Please sign in again to continue.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('KwartX'),
        actions: [
          PopupMenuButton<_HomeMenuAction>(
            tooltip: 'Menu',
            position: PopupMenuPosition.under,
            color: AppTheme.cardBackground,
            surfaceTintColor: Colors.transparent,
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem<_HomeMenuAction>(
                value: _HomeMenuAction.profile,
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<_HomeMenuAction>(
                value: _HomeMenuAction.invites,
                child: Row(
                  children: [
                    Icon(Icons.group_add_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Invites'),
                  ],
                ),
              ),
              PopupMenuItem<_HomeMenuAction>(
                value: _HomeMenuAction.logout,
                enabled: !_isSigningOut,
                child: Row(
                  children: [
                    _isSigningOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: AppLoadingIndicator(size: 18, strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    const SizedBox(width: 10),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseForm(title: 'Add Expense'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: StreamBuilder<List<RoommateModel>>(
            stream: _firestoreService.getRoommatesStream(uid),
            builder: (context, roommatesSnapshot) {
              final roommates = roommatesSnapshot.data ?? const <RoommateModel>[];
              return StreamBuilder<List<ExpenseModel>>(
                stream: _firestoreService.getExpensesStream(uid),
                builder: (context, snapshot) {
                  return _buildContent(snapshot, textTheme, uid, email, roommates);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.textTheme,
    required this.currentUserId,
    required this.email,
    required this.roommates,
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategory,
    required this.categories,
    required this.sortOption,
    required this.dateFilter,
    required this.hasActiveFilters,
    required this.summary,
    required this.topPayer,
    required this.allExpenses,
    required this.visibleExpenses,
    required this.settlements,
    required this.netBalanceCents,
    required this.userNameById,
    required this.monthTotalCents,
    required this.householdTotalCents,
    required this.dateFormatter,
    required this.formatCurrency,
    required this.onRefresh,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onDateFilterChanged,
    required this.onResetFilters,
    required this.onAddExpense,
    required this.onSplitBill,
    required this.onSummaryTap,
    required this.onInviteRoommates,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onConfirmDelete,
    required this.amountPerPerson,
    required this.safeLabel,
  });

  final TextTheme textTheme;
  final String currentUserId;
  final String email;
  final List<RoommateModel> roommates;
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedCategory;
  final List<String> categories;
  final _ExpenseSortOption sortOption;
  final _ExpenseDateFilter dateFilter;
  final bool hasActiveFilters;
  final _DashboardSummary summary;
  final MapEntry<String, double>? topPayer;
  final List<ExpenseModel> allExpenses;
  final List<ExpenseModel> visibleExpenses;
  final List<SettlementTransaction> settlements;
  final int netBalanceCents;
  final Map<String, String> userNameById;
  final int monthTotalCents;
  final int householdTotalCents;
  final DateFormat dateFormatter;
  final String Function(num value) formatCurrency;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_ExpenseSortOption> onSortChanged;
  final ValueChanged<_ExpenseDateFilter> onDateFilterChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onAddExpense;
  final VoidCallback onSplitBill;
  final VoidCallback onSummaryTap;
  final VoidCallback onInviteRoommates;
  final ValueChanged<ExpenseModel> onEditExpense;
  final Future<void> Function(ExpenseModel expense) onDeleteExpense;
  final Future<bool> Function(ExpenseModel expense) onConfirmDelete;
  final double Function(ExpenseModel expense) amountPerPerson;
  final String Function(String? raw, String fallback) safeLabel;

  @override
  Widget build(BuildContext context) {
    final showFilters = allExpenses.length >= 3;

    return RefreshIndicator(
      color: AppTheme.secondaryAccentBlue,
      backgroundColor: AppTheme.navOverlay,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.navOverlay,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.glowOutlineBlue.withAlpha(170),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RoommateContextCard(
            roommates: roommates,
            onInvitePressed: onInviteRoommates,
          ),
          const SizedBox(height: 12),
          BalanceHeroCard(
            netBalanceCents: netBalanceCents,
            monthTotalCents: monthTotalCents,
            householdTotalCents: householdTotalCents,
            topPayerLabel: topPayer?.key ?? 'No data yet',
          ),
          const SizedBox(height: 14),
          SettlementsSection(
            currentUserId: currentUserId,
            userNameById: userNameById,
            settlements: settlements,
          ),
          const SizedBox(height: 18),
          if (showFilters) ...[
            TextField(
              controller: searchController,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search by title, payer, or category',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: searchController.clear,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground.withAlpha(210),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.glowOutlineBlue.withAlpha(70),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        dropdownColor: AppTheme.cardBackground,
                        iconEnabledColor: AppTheme.textSecondary,
                        style: textTheme.bodyMedium,
                        isExpanded: true,
                        items: categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category == _HomeScreenState._allCategoriesKey
                                      ? 'Category: All'
                                      : category,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          onCategoryChanged(value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.navOverlay,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.glowOutlineBlue.withAlpha(90),
                    ),
                  ),
                  child: PopupMenuButton<_ExpenseSortOption>(
                    tooltip: 'Sort',
                    color: AppTheme.cardBackground,
                    icon: const Icon(
                      Icons.sort_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onSelected: onSortChanged,
                    itemBuilder: (context) {
                      return _ExpenseSortOption.values.map((option) {
                        return PopupMenuItem<_ExpenseSortOption>(
                          value: option,
                          child: Row(
                            children: [
                              Expanded(child: Text(option.label)),
                              if (sortOption == option)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppTheme.secondaryAccentBlue,
                                ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ExpenseDateFilter.values.map((option) {
                final selected = dateFilter == option;
                return ChoiceChip(
                  label: Text(option.label),
                  selected: selected,
                  onSelected: (_) => onDateFilterChanged(option),
                  selectedColor: AppTheme.glowOutlineBlue.withAlpha(80),
                  backgroundColor: AppTheme.navOverlay,
                  side: BorderSide(
                    color: selected
                        ? AppTheme.secondaryAccentBlue
                        : AppTheme.glowOutlineBlue.withAlpha(70),
                  ),
                  labelStyle: textTheme.bodySmall?.copyWith(
                    color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                );
              }).toList(),
            ),
          ],
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset filters'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          DarkCard(
            radius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total shared expenses',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasActiveFilters ? 'Current results' : 'All time results',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  formatCurrency(summary.totalAmount),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.totalCount} expense entries - Avg ${formatCurrency(summary.averageAmount)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  title: 'This month',
                  value: formatCurrency(summary.monthAmount),
                  subtitle: '${summary.monthCount} entries',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  title: 'Top payer',
                  value: topPayer?.key ?? 'No data',
                  subtitle: topPayer == null
                      ? '-'
                      : formatCurrency(topPayer!.value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Secondary actions', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSplitBill,
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Settle up'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSummaryTap,
                  icon: const Icon(Icons.bar_chart_rounded),
                  label: const Text('View report'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _GroupedSection(
            title: 'Paid by',
            entries: summary.payerTotals,
            emptyLabel: 'No payer data yet.',
            formatCurrency: formatCurrency,
          ),
          const SizedBox(height: 18),
          _CategorySection(
            entries: summary.categoryTotals,
            formatCurrency: formatCurrency,
          ),
          const SizedBox(height: 18),
          Text('Recent expenses', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _ExpensesListBody(
              key: ValueKey(
                'list_${allExpenses.length}_${visibleExpenses.length}_$searchQuery',
              ),
              allExpenses: allExpenses,
              visibleExpenses: visibleExpenses,
              onAddFirstExpense: onAddExpense,
              onResetFilters: onResetFilters,
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
              onConfirmDelete: onConfirmDelete,
              dateFormatter: dateFormatter,
              formatCurrency: formatCurrency,
              amountPerPerson: amountPerPerson,
              safeLabel: safeLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DarkCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({
    required this.title,
    required this.entries,
    required this.emptyLabel,
    required this.formatCurrency,
  });

  final String title;
  final List<MapEntry<String, double>> entries;
  final String emptyLabel;
  final String Function(num value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 12),
        DarkCard(
          radius: 16,
          padding: const EdgeInsets.all(14),
          child: entries.isEmpty
              ? Text(
                  emptyLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                )
              : Column(
                  children: entries.take(4).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatCurrency(entry.value),
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
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

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.entries, required this.formatCurrency});

  final List<MapEntry<String, double>> entries;
  final String Function(num value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        DarkCard(
          radius: 16,
          padding: const EdgeInsets.all(14),
          child: entries.isEmpty
              ? Text(
                  'No category data yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entries.take(6).map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.navOverlay,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.glowOutlineBlue.withAlpha(120),
                        ),
                      ),
                      child: Text(
                        '${entry.key}: ${formatCurrency(entry.value)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _ExpensesListBody extends StatelessWidget {
  const _ExpensesListBody({
    super.key,
    required this.allExpenses,
    required this.visibleExpenses,
    required this.onAddFirstExpense,
    required this.onResetFilters,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onConfirmDelete,
    required this.dateFormatter,
    required this.formatCurrency,
    required this.amountPerPerson,
    required this.safeLabel,
  });

  final List<ExpenseModel> allExpenses;
  final List<ExpenseModel> visibleExpenses;
  final VoidCallback onAddFirstExpense;
  final VoidCallback onResetFilters;
  final ValueChanged<ExpenseModel> onEditExpense;
  final Future<void> Function(ExpenseModel expense) onDeleteExpense;
  final Future<bool> Function(ExpenseModel expense) onConfirmDelete;
  final DateFormat dateFormatter;
  final String Function(num value) formatCurrency;
  final double Function(ExpenseModel expense) amountPerPerson;
  final String Function(String? raw, String fallback) safeLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (allExpenses.isEmpty) {
      return AppEmptyState(
        title: 'No recent expenses yet',
        subtitle: 'Start by adding your first shared expense.',
        icon: Icons.receipt_long_rounded,
        actionLabel: 'Add expense',
        onActionPressed: onAddFirstExpense,
      );
    }
    if (visibleExpenses.isEmpty) {
      return AppEmptyState(
        title: 'No matching expenses found',
        subtitle: 'Try changing your search or filters.',
        icon: Icons.filter_alt_off_rounded,
        actionLabel: 'Reset filters',
        onActionPressed: onResetFilters,
      );
    }
    return Column(
      children: visibleExpenses.map((expense) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey(expense.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => onConfirmDelete(expense),
            onDismissed: (_) => onDeleteExpense(expense),
            background: Container(
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withAlpha(180),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.textPrimary,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onEditExpense(expense),
              child: DarkCard(
                radius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.title, style: textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${safeLabel(expense.paidBy, AppConstants.unknownPayer)} - ${safeLabel(expense.category, AppConstants.defaultCategory)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormatter.format(expense.createdAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatCurrency(amountPerPerson(expense))} per person',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryAccentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatCurrency(expense.amount),
                      style: textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DashboardSummary {
  const _DashboardSummary({
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    required this.monthAmount,
    required this.monthCount,
    required this.payerTotals,
    required this.categoryTotals,
  });

  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final double monthAmount;
  final int monthCount;
  final List<MapEntry<String, double>> payerTotals;
  final List<MapEntry<String, double>> categoryTotals;
}

enum _ExpenseSortOption {
  newestFirst('Newest first'),
  oldestFirst('Oldest first'),
  highestAmount('Highest amount'),
  lowestAmount('Lowest amount');

  const _ExpenseSortOption(this.label);
  final String label;
}

enum _ExpenseDateFilter {
  allTime('All time'),
  thisWeek('This week'),
  thisMonth('This month');

  const _ExpenseDateFilter(this.label);
  final String label;
}

enum _HomeMenuAction { profile, invites, logout }
