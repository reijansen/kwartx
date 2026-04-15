import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/expense_reference_data.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dark_card.dart';
import '../widgets/primary_button.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({
    super.key,
    required this.title,
    this.existingExpense,
  });

  final String title;
  final ExpenseModel? existingExpense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidByController = TextEditingController();
  final _splitCountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = ExpenseReferenceData.defaultCategory;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.existingExpense;
    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _paidByController.text = expense.paidBy;
      _splitCountController.text = expense.splitCount.toString();
      final savedCategory = expense.category.trim();
      _selectedCategory = ExpenseReferenceData.categories.contains(savedCategory)
          ? savedCategory
          : ExpenseReferenceData.defaultCategory;
      return;
    }

    _splitCountController.text = '2';
    _selectedCategory = ExpenseReferenceData.defaultCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paidByController.dispose();
    _splitCountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_isSaving) {
      return;
    }
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final amount = _parseAmount(_amountController.text);
    final splitCount = int.tryParse(_splitCountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage(
        'Please enter a valid amount.',
        type: AppFeedbackType.error,
      );
      return;
    }
    if (splitCount == null || splitCount <= 0) {
      _showMessage(
        'Split count must be at least 1.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditMode) {
        await _firestoreService.updateExpense(widget.existingExpense!.id, {
          'title': _titleController.text.trim(),
          'amount': amount,
          'paidBy': _paidByController.text.trim(),
          'splitCount': splitCount,
          'category': _selectedCategory,
        });
      } else {
        final expense = ExpenseModel(
          id: '',
          title: _titleController.text.trim(),
          amount: amount,
          paidBy: _paidByController.text.trim(),
          splitCount: splitCount,
          category: _selectedCategory,
          createdAt: DateTime.now(),
        );
        await _firestoreService.addExpense(expense);
      }

      if (!mounted) {
        return;
      }
      _showMessage(
        _isEditMode ? 'Expense updated.' : 'Expense added.',
        type: AppFeedbackType.success,
      );
      Navigator.of(context).pop();
    } on FirebaseException {
      _showMessage(
        'Unable to save expense right now.',
        type: AppFeedbackType.error,
      );
    } catch (_) {
      _showMessage(
        'Something went wrong while saving expense.',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '');
    return double.tryParse(normalized);
  }

  void _showMessage(String message, {AppFeedbackType type = AppFeedbackType.info}) {
    if (!mounted) {
      return;
    }
    showAppSnackBar(context, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
          child: SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: DarkCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Expense details', style: textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          _isEditMode
                              ? 'Update the fields below to save changes.'
                              : 'Fill in the fields below to add an expense.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Title',
                          hintText: 'Dinner, groceries, transport...',
                          prefixIcon: Icons.receipt_long_rounded,
                          controller: _titleController,
                          enabled: !_isSaving,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Amount',
                          hintText: '0.00',
                          prefixIcon: Icons.currency_exchange_rounded,
                          controller: _amountController,
                          enabled: !_isSaving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Amount is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Paid By',
                          hintText: 'Who paid?',
                          prefixIcon: Icons.person_outline_rounded,
                          controller: _paidByController,
                          enabled: !_isSaving,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Paid by is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Split Count',
                          hintText: '2',
                          prefixIcon: Icons.group_outlined,
                          controller: _splitCountController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Split count is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          dropdownColor: AppTheme.cardBackground,
                          items: ExpenseReferenceData.categories
                              .map(
                                (category) => DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: _isEditMode ? 'Update Expense' : 'Add Expense',
                          isLoading: _isSaving,
                          onPressed: _saveExpense,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
