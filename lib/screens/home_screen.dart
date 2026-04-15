import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/dark_card.dart';
import 'expense_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormatter = DateFormat('MMM d, y');
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '\u20B1',
    decimalDigits: 2,
  );
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
    final categories = expenses
        .map((expense) => _safeLabel(expense.category, 'General'))
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
      final category = _safeLabel(expense.category, 'General');
      final paidBy = _safeLabel(expense.paidBy, 'Unknown payer');
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
      message: 'You will be returned to the sign-in screen.',
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
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to sign out. Please try again.',
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
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
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
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Failed to delete expense.',
        type: AppFeedbackType.error,
      );
    }
  }

  _DashboardSummary _buildSummary(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final thisMonthExpenses = expenses
        .where(
          (expense) =>
              expense.createdAt.year == now.year &&
              expense.createdAt.month == now.month,
        )
        .toList();

    final totalAmount = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final monthAmount = thisMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final averageAmount = expenses.isEmpty
        ? 0.0
        : totalAmount / expenses.length;

    final byPayer = <String, double>{};
    final byCategory = <String, double>{};
    for (final expense in expenses) {
      final payer = _safeLabel(expense.paidBy, 'Unknown payer');
      final category = _safeLabel(expense.category, 'General');
      byPayer[payer] = (byPayer[payer] ?? 0) + expense.amount;
      byCategory[category] = (byCategory[category] ?? 0) + expense.amount;
    }

    final payerTotals = byPayer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoryTotals = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _DashboardSummary(
      totalAmount: totalAmount,
      totalCount: expenses.length,
      averageAmount: averageAmount,
      monthAmount: monthAmount,
      monthCount: thisMonthExpenses.length,
      payerTotals: payerTotals,
      categoryTotals: categoryTotals,
    );
  }

  Widget _buildContent(
    AsyncSnapshot<List<ExpenseModel>> snapshot,
    TextTheme textTheme,
    String email,
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
    final topPayer = summary.payerTotals.isEmpty ? null : summary.payerTotals.first;

    return _DashboardBody(
      textTheme: textTheme,
      email: email,
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
      dateFormatter: _dateFormatter,
      currencyFormatter: _currencyFormatter,
      onRefresh: _onRefresh,
      onCategoryChanged: (value) => setState(() => _selectedCategory = value),
      onSortChanged: (value) => setState(() => _sortOption = value),
      onDateFilterChanged: (value) => setState(() => _dateFilter = value),
      onResetFilters: _resetFilters,
      onAddExpense: () => _openExpenseForm(title: 'Add Expense'),
      onSplitBill: () => _openExpenseForm(title: 'Split Bill'),
      onSummaryTap: () => showAppSnackBar(
        context,
        message: 'Summary view is coming soon.',
      ),
      onMoreTap: () => showAppSnackBar(
        context,
        message: 'More actions are coming soon.',
      ),
      onEditExpense: (expense) => _openExpenseForm(
        title: 'Edit Expense',
        expense: expense,
      ),
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
          IconButton(
            onPressed: _isSigningOut ? null : _handleSignOut,
            tooltip: 'Logout',
            icon: _isSigningOut
                ? const AppLoadingIndicator(size: 18, strokeWidth: 2)
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: StreamBuilder<List<ExpenseModel>>(
            stream: _firestoreService.getExpensesStream(uid),
            builder: (context, snapshot) {
              return _buildContent(snapshot, textTheme, email);
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
    required this.email,
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
    required this.dateFormatter,
    required this.currencyFormatter,
    required this.onRefresh,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onDateFilterChanged,
    required this.onResetFilters,
    required this.onAddExpense,
    required this.onSplitBill,
    required this.onSummaryTap,
    required this.onMoreTap,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onConfirmDelete,
    required this.amountPerPerson,
    required this.safeLabel,
  });

  final TextTheme textTheme;
  final String email;
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
  final DateFormat dateFormatter;
  final NumberFormat currencyFormatter;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_ExpenseSortOption> onSortChanged;
  final ValueChanged<_ExpenseDateFilter> onDateFilterChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onAddExpense;
  final VoidCallback onSplitBill;
  final VoidCallback onSummaryTap;
  final VoidCallback onMoreTap;
  final ValueChanged<ExpenseModel> onEditExpense;
  final Future<void> Function(ExpenseModel expense) onDeleteExpense;
  final Future<bool> Function(ExpenseModel expense) onConfirmDelete;
  final double Function(ExpenseModel expense) amountPerPerson;
  final String Function(String? raw, String fallback) safeLabel;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 18),
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
                  currencyFormatter.format(summary.totalAmount),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.totalCount} expense entries - Avg ${currencyFormatter.format(summary.averageAmount)}',
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
                  value: currencyFormatter.format(summary.monthAmount),
                  subtitle: '${summary.monthCount} entries',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  title: 'Top payer',
                  value: topPayer?.key ?? 'No data',
                  subtitle: topPayer == null ? '-' : currencyFormatter.format(topPayer!.value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Quick actions', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickAction(icon: Icons.add_circle_outline_rounded, label: 'Add', onTap: onAddExpense),
              _QuickAction(icon: Icons.call_split_rounded, label: 'Split', onTap: onSplitBill),
              _QuickAction(icon: Icons.bar_chart_rounded, label: 'Summary', onTap: onSummaryTap),
              _QuickAction(icon: Icons.more_horiz_rounded, label: 'More', onTap: onMoreTap),
            ],
          ),
          const SizedBox(height: 18),
          _GroupedSection(
            title: 'Paid by',
            entries: summary.payerTotals,
            emptyLabel: 'No payer data yet.',
            currencyFormatter: currencyFormatter,
          ),
          const SizedBox(height: 18),
          _CategorySection(
            entries: summary.categoryTotals,
            currencyFormatter: currencyFormatter,
          ),
          const SizedBox(height: 18),
          Text('Recent expenses', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _ExpensesListBody(
              key: ValueKey('list_${allExpenses.length}_${visibleExpenses.length}_$searchQuery'),
              allExpenses: allExpenses,
              visibleExpenses: visibleExpenses,
              onAddFirstExpense: onAddExpense,
              onResetFilters: onResetFilters,
              onEditExpense: onEditExpense,
              onDeleteExpense: onDeleteExpense,
              onConfirmDelete: onConfirmDelete,
              dateFormatter: dateFormatter,
              currencyFormatter: currencyFormatter,
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
    required this.currencyFormatter,
  });

  final String title;
  final List<MapEntry<String, double>> entries;
  final String emptyLabel;
  final NumberFormat currencyFormatter;

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
                            currencyFormatter.format(entry.value),
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
  const _CategorySection({
    required this.entries,
    required this.currencyFormatter,
  });

  final List<MapEntry<String, double>> entries;
  final NumberFormat currencyFormatter;

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
                        '${entry.key}: ${currencyFormatter.format(entry.value)}',
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
    required this.currencyFormatter,
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
  final NumberFormat currencyFormatter;
  final double Function(ExpenseModel expense) amountPerPerson;
  final String Function(String? raw, String fallback) safeLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (allExpenses.isEmpty) {
      return AppEmptyState(
        title: 'No expenses yet',
        subtitle: 'Add your first shared expense to get started.',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.title, style: textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${safeLabel(expense.paidBy, 'Unknown payer')} - ${safeLabel(expense.category, 'General')}',
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
                            '${currencyFormatter.format(amountPerPerson(expense))} per person',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryAccentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      currencyFormatter.format(expense.amount),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.navOverlay,
                border: Border.all(
                  color: AppTheme.glowOutlineBlue.withAlpha(140),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x442D7DFF),
                    blurRadius: 16,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.secondaryAccentBlue),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
