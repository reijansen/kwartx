import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/input_validators.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.authService,
    required this.onNavigateToSignUp,
  });

  final AuthService authService;
  final VoidCallback onNavigateToSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _inlineMessage;
  AppFeedbackType _inlineType = AppFeedbackType.info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
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
      await widget.authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _showInlineFeedback(
        'Signed in successfully. Redirecting...',
        type: AppFeedbackType.success,
      );
    } on FirebaseAuthException catch (error) {
      _showInlineFeedback(
        mapAppErrorMessage(
          error,
          fallback: 'Unable to sign in right now. Please try again.',
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

  void _showMessage(
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    if (!mounted) {
      return;
    }
    showAppSnackBar(context, message: message, type: type);
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

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();
    final initialEmail = _emailController.text.trim();
    final TextEditingController emailController = TextEditingController(
      text: initialEmail,
    );
    String? dialogError;
    bool isSending = false;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your account email and we will send a reset link.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isSending,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    AppInlineFeedback(
                      message: dialogError!,
                      type: AppFeedbackType.error,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final emailValidationError = InputValidators.email(
                            emailController.text,
                          );
                          if (emailValidationError != null) {
                            setDialogState(() {
                              dialogError = emailValidationError;
                            });
                            return;
                          }

                          setDialogState(() {
                            dialogError = null;
                            isSending = true;
                          });

                          try {
                            await widget.authService.sendPasswordResetEmail(
                              email: emailController.text.trim(),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop(true);
                          } catch (error) {
                            setDialogState(() {
                              dialogError = mapAppErrorMessage(
                                error,
                                fallback:
                                    'Unable to send reset email right now.',
                              );
                              isSending = false;
                            });
                          }
                        },
                  child: Text(isSending ? 'Sending...' : 'Send reset link'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();

    if (!mounted || shouldSend != true) {
      return;
    }

    _showInlineFeedback(
      'Password reset email sent. Please check your inbox.',
      type: AppFeedbackType.success,
    );
    _showMessage('Password reset email sent.', type: AppFeedbackType.success);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthShell(
      topLabel: 'Welcome back',
      title: 'Sign in to KwartX',
      subtitle:
          'Track shared expenses, settle balances, and stay in sync with your group.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _handleSignIn(),
              validator: (value) {
                return InputValidators.signInPassword(value);
              },
            ),
            const SizedBox(height: 10),
            if (_inlineMessage != null) ...[
              const SizedBox(height: 10),
              AppInlineFeedback(message: _inlineMessage!, type: _inlineType),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Sign In',
              isLoading: _isLoading,
              onPressed: _handleSignIn,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('No account? ', style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onNavigateToSignUp,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'Sign Up',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryAccentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryAccentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
