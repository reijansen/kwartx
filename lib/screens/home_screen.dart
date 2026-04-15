import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
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
    symbol: '₱',
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

  Future<void> _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.authService.signOut();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _openExpenseForm({
    required String title,
    ExpenseModel? expense,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExpenseFormScreen(title: title, existingExpense: expense),
      ),
    );
  }

  Future<bool> _confirmDelete(ExpenseModel expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Delete Expense'),
          content: Text('Delete "${expense.title}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.dangerRed),
              ),
            ),
          ],
        );
      },
    );

    return shouldDelete ?? false;
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    try {
      await _firestoreService.deleteExpense(expense.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense deleted.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete expense.')),
      );
    }
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
            child: Text('Session unavailable. Please sign in again.'),
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
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textPrimary,
                    ),
                  )
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.secondaryAccentBlue,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Unable to load expenses right now.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
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

              return ListView(
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
                    controller: _searchController,
                    style: textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search by title, payer, or category',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                              },
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
                              value: effectiveCategory,
                              dropdownColor: AppTheme.cardBackground,
                              iconEnabledColor: AppTheme.textSecondary,
                              style: textTheme.bodyMedium,
                              isExpanded: true,
                              items: categories
                                  .map(
                                    (category) => DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(
                                        category == _allCategoriesKey
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
                                setState(() {
                                  _selectedCategory = value;
                                });
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
                          onSelected: (value) {
                            setState(() {
                              _sortOption = value;
                            });
                          },
                          itemBuilder: (context) {
                            return _ExpenseSortOption.values.map((option) {
                              return PopupMenuItem<_ExpenseSortOption>(
                                value: option,
                                child: Row(
                                  children: [
                                    Expanded(child: Text(option.label)),
                                    if (_sortOption == option)
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
                      final selected = _dateFilter == option;
                      return ChoiceChip(
                        label: Text(option.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _dateFilter = option;
                          });
                        },
                        selectedColor: AppTheme.glowOutlineBlue.withAlpha(80),
                        backgroundColor: AppTheme.navOverlay,
                        side: BorderSide(
                          color: selected
                              ? AppTheme.secondaryAccentBlue
                              : AppTheme.glowOutlineBlue.withAlpha(70),
                        ),
                        labelStyle: textTheme.bodySmall?.copyWith(
                          color: selected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _resetFilters,
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
                          _hasActiveFilters
                              ? 'Current results'
                              : 'All time results',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currencyFormatter.format(summary.totalAmount),
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${summary.totalCount} expense entries - Avg ${_currencyFormatter.format(summary.averageAmount)}',
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
                        child: DarkCard(
                          radius: 16,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This month',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _currencyFormatter.format(summary.monthAmount),
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${summary.monthCount} entries',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DarkCard(
                          radius: 16,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Top payer',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                topPayer?.key ?? 'No data',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                topPayer == null
                                    ? '-'
                                    : _currencyFormatter.format(topPayer.value),
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Quick actions', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Add',
                        onTap: () => _openExpenseForm(title: 'Add Expense'),
                      ),
                      _QuickAction(
                        icon: Icons.call_split_rounded,
                        label: 'Split',
                        onTap: () => _openExpenseForm(title: 'Split Bill'),
                      ),
                      _QuickAction(
                        icon: Icons.bar_chart_rounded,
                        label: 'Summary',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Summary view is coming soon.'),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.more_horiz_rounded,
                        label: 'More',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('More actions are coming soon.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Paid by', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DarkCard(
                    radius: 16,
                    padding: const EdgeInsets.all(14),
                    child: summary.payerTotals.isEmpty
                        ? Text(
                            'No payer data yet.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                          )
                        : Column(
                            children: summary.payerTotals
                                .take(4)
                                .map(
                                  (entry) => Padding(
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
                                          _currencyFormatter.format(entry.value),
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text('Categories', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DarkCard(
                    radius: 16,
                    padding: const EdgeInsets.all(14),
                    child: summary.categoryTotals.isEmpty
                        ? Text(
                            'No category data yet.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: summary.categoryTotals
                                .take(6)
                                .map(
                                  (entry) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.navOverlay,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppTheme.glowOutlineBlue
                                            .withAlpha(120),
                                      ),
                                    ),
                                    child: Text(
                                      '${entry.key}: ${_currencyFormatter.format(entry.value)}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text('Recent expenses', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (allExpenses.isEmpty)
                    DarkCard(
                      radius: 16,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No expenses yet. Add your first expense.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (allExpenses.isNotEmpty && expenses.isEmpty)
                    DarkCard(
                      radius: 16,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Text(
                              'No matching expenses found.',
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try changing your search or filters.',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppTheme.mutedText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...expenses.map((expense) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(expense),
                        onDismissed: (_) => _deleteExpense(expense),
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
                          onTap: () {
                            _openExpenseForm(
                              title: 'Edit Expense',
                              expense: expense,
                            );
                          },
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_safeLabel(expense.paidBy, 'Unknown payer')} - ${_safeLabel(expense.category, 'General')}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dateFormatter.format(
                                          expense.createdAt,
                                        ),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_currencyFormatter.format(_amountPerPerson(expense))} per person',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTheme.secondaryAccentBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _currencyFormatter.format(expense.amount),
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
                  }),
                ],
              );
            },
          ),
        ),
      ),
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
