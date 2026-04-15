import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
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
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
      _categoryController.text = expense.category;
      return;
    }

    _splitCountController.text = '2';
    _categoryController.text = 'General';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paidByController.dispose();
    _splitCountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    final splitCount = int.tryParse(_splitCountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }
    if (splitCount == null || splitCount <= 0) {
      _showMessage('Split count must be at least 1.');
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
          'category': _categoryController.text.trim(),
        });
      } else {
        final expense = ExpenseModel(
          id: '',
          title: _titleController.text.trim(),
          amount: amount,
          paidBy: _paidByController.text.trim(),
          splitCount: splitCount,
          category: _categoryController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _firestoreService.addExpense(expense);
      }

      if (!mounted) {
        return;
      }
      _showMessage(_isEditMode ? 'Expense updated.' : 'Expense added.');
      Navigator.of(context).pop();
    } on FirebaseException {
      _showMessage('Unable to save expense right now.');
    } catch (_) {
      _showMessage('Something went wrong while saving expense.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DarkCard(
              radius: 20,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Expense details', style: textTheme.titleLarge),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Amount',
                      hintText: '0.00',
                      prefixIcon: Icons.attach_money_rounded,
                      controller: _amountController,
                      enabled: !_isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Amount is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Split Count',
                      hintText: '2',
                      prefixIcon: Icons.group_outlined,
                      controller: _splitCountController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Split count is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Category',
                      hintText: 'General',
                      prefixIcon: Icons.category_outlined,
                      controller: _categoryController,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveExpense(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Category is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
    );
  }
}
