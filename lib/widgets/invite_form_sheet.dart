import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/custom_text_field.dart';

class InviteFormSheet extends StatefulWidget {
  const InviteFormSheet({
    super.key,
    required this.currentUserEmail,
    required this.onSendInvite,
  });

  final String currentUserEmail;
  final Future<void> Function({
    required String recipientEmail,
    String? message,
  })
  onSendInvite;

  @override
  State<InviteFormSheet> createState() => _InviteFormSheetState();
}

class _InviteFormSheetState extends State<InviteFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_validateEmail)
      ..dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final value = _emailController.text.trim();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (_isEmailValid != isValid) {
      setState(() {
        _isEmailValid = isValid;
      });
    }
  }

  String _normalize(String value) => value.trim().toLowerCase();

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSendInvite(
        recipientEmail: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canSubmit = _isEmailValid && !_isSubmitting;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + viewInsets.bottom),
      child: Material(
        color: AppTheme.cardBackground,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Invite Roommate',
                        style: textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Send an email invite to connect a roommate.',
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Roommate Email',
                  hintText: 'roommate@example.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isSubmitting,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) {
                      return 'Email is required.';
                    }
                    final valid = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email);
                    if (!valid) {
                      return 'Please enter a valid email.';
                    }
                    if (_normalize(email) == _normalize(widget.currentUserEmail)) {
                      return 'You cannot invite your own email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Message (Optional)',
                  hintText: 'Add a short note',
                  prefixIcon: Icons.message_outlined,
                  controller: _messageController,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: canSubmit ? _submit : null,
                  icon: _isSubmitting
                      ? const AppLoadingIndicator(size: 16, strokeWidth: 2)
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Sending...' : 'Send Invite'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
