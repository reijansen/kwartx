import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense_model.dart';
import '../services/expense_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_feedback.dart';
import '../widgets/dark_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.expenses,
  });

  final List<ExpenseModel> expenses;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '\u20B1',
    decimalDigits: 2,
  );
  ReportScope _scope = ReportScope.allTime;

  ExpenseReportData get _report =>
      ExpenseReportService.buildReport(widget.expenses, scope: _scope);

  Future<void> _shareReport() async {
    final text = ExpenseReportService.buildShareText(
      _report,
      formatCurrency: _currencyFormatter.format,
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'KwartX Expense Report (${_scope.label})',
        ),
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Report ready to share.',
        type: AppFeedbackType.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Could not share report right now.',
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Report'),
        actions: [
          IconButton(
            tooltip: 'Share report',
            onPressed: report.totalEntries == 0 ? null : _shareReport,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DarkCard(
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KwartX Expense Report',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select scope and review your summary before sharing.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ReportScope.values.map((scope) {
                        final selected = _scope == scope;
                        return ChoiceChip(
                          label: Text(scope.label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _scope = scope;
                            });
                          },
                          selectedColor: AppTheme.glowOutlineBlue.withAlpha(85),
                          backgroundColor: AppTheme.navOverlay,
                          side: BorderSide(
                            color: selected
                                ? AppTheme.secondaryAccentBlue
                                : AppTheme.glowOutlineBlue.withAlpha(80),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (report.totalEntries == 0)
                const AppEmptyState(
                  title: 'No data for this scope',
                  subtitle: 'Try a wider date scope to generate a report.',
                  icon: Icons.insert_chart_outlined_rounded,
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'Total Expenses',
                        value: _currencyFormatter.format(report.totalExpenses),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'Entries',
                        value: report.totalEntries.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'This Month',
                        value: _currencyFormatter.format(report.thisMonthTotal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'Average',
                        value: _currencyFormatter.format(report.averageExpense),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _BreakdownCard(
                  title: 'Category Breakdown',
                  entries: report.categoryTotals,
                  currencyFormatter: _currencyFormatter,
                  emptyLabel: 'No category data available.',
                ),
                const SizedBox(height: 12),
                _BreakdownCard(
                  title: 'Paid By',
                  entries: report.payerTotals,
                  currencyFormatter: _currencyFormatter,
                  emptyLabel: 'No payer data available.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

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
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.entries,
    required this.currencyFormatter,
    required this.emptyLabel,
  });

  final String title;
  final List<MapEntry<String, double>> entries;
  final NumberFormat currencyFormatter;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DarkCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              emptyLabel,
              style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
          ...entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: textTheme.bodyMedium,
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
          }),
        ],
      ),
    );
  }
}
