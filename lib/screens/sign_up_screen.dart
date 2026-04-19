import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/input_validators.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.authService,
    required this.onNavigateToSignIn,
  });

  final AuthService authService;
  final VoidCallback onNavigateToSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _inlineMessage;
  AppFeedbackType _inlineType = AppFeedbackType.info;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _inlineMessage = null;
    });

    try {
      await widget.authService.signUpWithEmailPassword(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _showInlineFeedback(
        'Account created successfully. You can now start using KwartX.',
        type: AppFeedbackType.success,
      );
    } on FirebaseAuthException catch (error) {
      _showInlineFeedback(
        mapAppErrorMessage(
          error,
          fallback: 'Unable to create your account right now.',
        ),
        type: AppFeedbackType.error,
      );
    } catch (error) {
      _showInlineFeedback(
        mapAppErrorMessage(error),
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showInlineFeedback(
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _inlineMessage = message;
      _inlineType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthShell(
      topLabel: 'New here?',
      title: 'Create your account',
      subtitle:
          'Start organizing shared bills, trips, and everyday group expenses in one place.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'Full Name',
              hintText: 'Juan Dela Cruz',
              prefixIcon: Icons.person_outline_rounded,
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: InputValidators.displayName,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone Number',
              hintText: '+63 9XX XXX XXXX',
              prefixIcon: Icons.call_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Phone number is required.';
                }
                return InputValidators.phone(value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              hintText: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (value) {
                return InputValidators.email(value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Password',
              hintText: 'Create a password',
              prefixIcon: Icons.lock_outline_rounded,
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (value) {
                return InputValidators.signUpPassword(value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: Icons.lock_reset_rounded,
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _handleSignUp(),
              validator: (value) {
                final confirmPassword = value?.trim() ?? '';
                if (confirmPassword.isEmpty) {
                  return 'Confirm your password.';
                }
                if (InputValidators.signUpPassword(
                      _passwordController.text,
                    ) !=
                    null) {
                  return 'Create a stronger password first.';
                }
                if (confirmPassword != _passwordController.text.trim()) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            if (_inlineMessage != null) ...[
              const SizedBox(height: 14),
              AppInlineFeedback(
                message: _inlineMessage!,
                type: _inlineType,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Sign Up',
              isLoading: _isLoading,
              onPressed: _handleSignUp,
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : widget.onNavigateToSignIn,
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: AppTheme.secondaryAccentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
