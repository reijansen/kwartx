import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense_model.dart';
import '../models/expense_participant_model.dart';
import '../models/roommate_model.dart';
import '../models/user_profile_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dark_card.dart';
import '../widgets/primary_button.dart';
import 'invite_roommate_screen.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({
    super.key,
    this.existingExpense,
    this.asDialog = false,
  });

  final ExpenseModel? existingExpense;
  final bool asDialog;

  static Future<bool?> show(
    BuildContext context, {
    ExpenseModel? existingExpense,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.94,
        child: ExpenseFormScreen(
          existingExpense: existingExpense,
          asDialog: true,
        ),
      ),
    );
  }

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  UserProfileModel? _currentProfile;
  List<RoommateModel> _roommates = const [];
  String? _paidByUserId;
  String _selectedCategory = 'misc';
  String _splitType = 'equal';
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingMeta = true;
  String? _loadError;
  bool _needsRoomSetup = false;
  bool _needsAuth = false;
  bool _isSaving = false;

  final Set<String> _selectedParticipants = <String>{};
  final Map<String, TextEditingController> _splitControllers = {};

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null || authUser.uid.isEmpty) {
        _needsAuth = true;
        _loadError = 'Your session has expired.';
        return;
      }

      final profile = await _firestoreService.getCurrentUserProfileModel();
      if (profile == null || profile.householdId.trim().isEmpty) {
        _needsRoomSetup = true;
        _loadError = 'No active room yet.';
        return;
      }
      final roommates = await _firestoreService.getCurrentUserRoommates();
      if (!mounted) {
        return;
      }
      _currentProfile = profile;
      _roommates = roommates;

      final people = _people;
      for (final person in people) {
        _splitControllers[person.id] ??= TextEditingController();
      }

      final existing = widget.existingExpense;
      if (existing != null) {
        _titleController.text = existing.title;
        _amountController.text = (existing.amountCents / 100).toStringAsFixed(2);
        _notesController.text = existing.notes ?? '';
        _selectedDate = existing.date;
        _dateController.text = _formatDate(existing.date);
        _selectedCategory = existing.category;
        _splitType = existing.splitType;
        _paidByUserId = existing.paidByUserId;
        _selectedParticipants
          ..clear()
          ..addAll(existing.participantUserIds);
        final existingConfig = existing.splitConfig;
        for (final person in people) {
          final value = existingConfig[person.id]?.toString() ?? '';
          _splitControllers[person.id]?.text = value;
        }
      } else {
        final defaultPayer = _currentProfile?.id;
        if (defaultPayer != null) {
          _paidByUserId = defaultPayer;
        }
        _selectedParticipants
          ..clear()
          ..addAll(people.map((p) => p.id));
        _dateController.text = _formatDate(_selectedDate);
      }
    } catch (error) {
      final fallback = mapAppErrorMessage(
        error,
        fallback: 'Unable to load expense form right now.',
      );
      final raw = error.toString().toLowerCase();
      final firebaseMessage =
          error is FirebaseException ? (error.message ?? '').toLowerCase() : '';
      final detectedNoRoom = raw.contains('no household') ||
          raw.contains('no active room') ||
          raw.contains('no active household membership') ||
          firebaseMessage.contains('no household') ||
          firebaseMessage.contains('no active household membership');
      final detectedNoAuth = raw.contains('not authenticated') ||
          firebaseMessage.contains('not authenticated');
      _needsAuth = detectedNoAuth;
      _needsRoomSetup = detectedNoRoom;
      _loadError = detectedNoAuth
          ? 'Your session has expired.'
          : (detectedNoRoom ? 'No active room yet.' : fallback);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMeta = false;
        });
      }
    }
  }

  Future<void> _openRoomsTab() async {
    if (widget.asDialog && mounted) {
      Navigator.of(context).pop(false);
    }
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const InviteRoommateScreen(initialTabIndex: 3),
      ),
    );
  }

  List<_PersonOption> get _people {
    final profile = _currentProfile;
    if (profile == null) {
      return const [];
    }
    final list = <_PersonOption>[
      _PersonOption(id: profile.id, name: profile.fullName),
    ];
    for (final roommate in _roommates) {
      final id = roommate.linkedUid;
      if (id == null || id.isEmpty) {
        continue;
      }
      list.add(_PersonOption(id: id, name: roommate.displayName));
    }
    return list;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 1, 1),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = picked;
      _dateController.text = _formatDate(picked);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final amountRaw = _amountController.text.trim().replaceAll(',', '');
    final amountDouble = double.tryParse(amountRaw);
    if (amountDouble == null || amountDouble <= 0) {
      showAppSnackBar(
        context,
        message: 'Enter a valid amount greater than zero.',
        type: AppFeedbackType.error,
      );
      return;
    }
    final amountCents = (amountDouble * 100).round();
    if (_paidByUserId == null || _paidByUserId!.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Choose who paid for this expense.',
        type: AppFeedbackType.error,
      );
      return;
    }
    if (_selectedParticipants.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Select at least one participant.',
        type: AppFeedbackType.error,
      );
      return;
    }

    final splitConfig = <String, dynamic>{};
    final participants = <ExpenseParticipantModel>[];
    var exactTotal = 0;
    var percentageTotal = 0;
    var sharesTotal = 0;

    for (final person in _people.where((p) => _selectedParticipants.contains(p.id))) {
      final raw = _splitControllers[person.id]?.text.trim() ?? '';
      int? exact;
      int? bps;
      int? shares;
      if (_splitType == 'exact') {
        final parsed = double.tryParse(raw.isEmpty ? '0' : raw);
        exact = parsed == null ? -1 : (parsed * 100).round();
        exactTotal += exact;
        splitConfig[person.id] = parsed ?? 0;
      } else if (_splitType == 'percentage') {
        final parsed = double.tryParse(raw.isEmpty ? '0' : raw);
        bps = parsed == null ? -1 : (parsed * 100).round();
        percentageTotal += bps;
        splitConfig[person.id] = parsed ?? 0;
      } else if (_splitType == 'shares') {
        shares = int.tryParse(raw.isEmpty ? '0' : raw) ?? -1;
        sharesTotal += shares;
        splitConfig[person.id] = shares;
      }
      participants.add(
        ExpenseParticipantModel(
          userId: person.id,
          fullName: person.name,
          exactCents: exact,
          percentageBps: bps,
          shares: shares,
        ),
      );
    }

    if (_splitType == 'exact' && exactTotal != amountCents) {
      showAppSnackBar(
        context,
        message: 'Exact split values must equal total amount.',
        type: AppFeedbackType.error,
      );
      return;
    }
    if (_splitType == 'percentage' && percentageTotal != 10000) {
      showAppSnackBar(
        context,
        message: 'Percentage split must total 100%.',
        type: AppFeedbackType.error,
      );
      return;
    }
    if (_splitType == 'shares' && sharesTotal <= 0) {
      showAppSnackBar(
        context,
        message: 'Shares must be greater than zero.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final payerCandidates = _people.where((p) => p.id == _paidByUserId);
      if (payerCandidates.isEmpty) {
        throw StateError('Selected payer is no longer available.');
      }
      final paidBy = payerCandidates.first;
      final expense = ExpenseModel(
        id: widget.existingExpense?.id ?? '',
        householdId: widget.existingExpense?.householdId ?? '',
        title: _titleController.text.trim(),
        amountCents: amountCents,
        paidByUserId: paidBy.id,
        paidByName: paidBy.name,
        createdByUserId: _currentProfile?.id ?? '',
        date: _selectedDate,
        category: _selectedCategory,
        splitType: _splitType,
        participantUserIds: _selectedParticipants.toList(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        splitConfig: splitConfig,
      );
      await _firestoreService.upsertExpense(expense: expense, participants: participants);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: widget.existingExpense == null ? 'Expense added.' : 'Expense updated.',
        type: AppFeedbackType.success,
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: mapAppErrorMessage(error, fallback: 'Unable to save expense.'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMeta) {
      return const Material(
        color: Colors.transparent,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (_loadError != null) {
      return Material(
        color: widget.asDialog ? Colors.white : Colors.transparent,
        borderRadius: widget.asDialog
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.zero,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _needsAuth
                      ? 'Please sign in again'
                      : (_needsRoomSetup ? 'Join or create a room first' : _loadError!),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (_needsRoomSetup)
                  Text(
                    'Expenses are tied to a room. Open Rooms to create or join one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                if (_needsAuth)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  )
                else if (_needsRoomSetup)
                  FilledButton(
                    onPressed: _openRoomsTab,
                    child: const Text('Go to Rooms'),
                  )
                else
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _isLoadingMeta = true;
                        _loadError = null;
                        _needsRoomSetup = false;
                      });
                      _loadMeta();
                    },
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final content = Container(
      decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
      child: SafeArea(
        top: !widget.asDialog,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DarkCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.asDialog) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.existingExpense == null ? 'Add Expense' : 'Edit Expense',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!widget.asDialog) ...[
                    Text(
                      widget.existingExpense == null ? 'Add Expense' : 'Edit Expense',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                  ],
                  CustomTextField(
                    label: 'Title',
                    hintText: 'Rent, groceries, water bill',
                    controller: _titleController,
                    prefixIcon: Icons.receipt_long_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Amount',
                    hintText: '0.00',
                    controller: _amountController,
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount is required.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      'rent',
                      'electricity',
                      'water',
                      'wifi',
                      'groceries',
                      'repairs',
                      'misc',
                    ].map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category[0].toUpperCase() + category.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value ?? 'misc'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _paidByUserId,
                    decoration: const InputDecoration(
                      labelText: 'Paid by',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: _people
                        .map((person) => DropdownMenuItem<String>(
                              value: person.id,
                              child: Text(person.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _paidByUserId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _splitType,
                    decoration: const InputDecoration(
                      labelText: 'Split type',
                      prefixIcon: Icon(Icons.pie_chart_outline_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'equal', child: Text('Equal')),
                      DropdownMenuItem(value: 'exact', child: Text('Exact amounts')),
                      DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                      DropdownMenuItem(value: 'shares', child: Text('Shares/weights')),
                    ],
                    onChanged: (value) => setState(() => _splitType = value ?? 'equal'),
                  ),
                  const SizedBox(height: 14),
                  Text('Participants', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _people.map((person) {
                      final selected = _selectedParticipants.contains(person.id);
                      return FilterChip(
                        selected: selected,
                        label: Text(person.name),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedParticipants.add(person.id);
                            } else {
                              _selectedParticipants.remove(person.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_splitType != 'equal') ...[
                    const SizedBox(height: 12),
                    ..._people.where((person) => _selectedParticipants.contains(person.id)).map((person) {
                      final label = switch (_splitType) {
                        'exact' => 'Exact amount',
                        'percentage' => 'Percentage',
                        'shares' => 'Shares',
                        _ => 'Value',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CustomTextField(
                          label: '${person.name} - $label',
                          hintText: _splitType == 'percentage' ? 'e.g. 25' : 'e.g. 1',
                          controller: _splitControllers[person.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 6),
                  CustomTextField(
                    label: 'Notes',
                    hintText: 'Optional notes',
                    controller: _notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: widget.existingExpense == null ? 'Add Expense' : 'Save Changes',
                    isLoading: _isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.asDialog) {
      return Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return Scaffold(body: content);
  }
}

class _PersonOption {
  const _PersonOption({required this.id, required this.name});

  final String id;
  final String name;
}
