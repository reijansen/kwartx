import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_error_mapper.dart';
import '../theme/app_theme.dart';

enum AppFeedbackType { success, error, info }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final style = switch (type) {
    AppFeedbackType.success => (
      icon: Icons.check_circle_rounded,
      color: AppTheme.successGreen,
    ),
    AppFeedbackType.error => (
      icon: Icons.error_rounded,
      color: AppTheme.dangerRed,
    ),
    AppFeedbackType.info => (
      icon: Icons.info_rounded,
      color: AppTheme.secondaryAccentBlue,
    ),
  };

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(style.icon, color: style.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String mapAppErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is FirebaseAuthException) {
    return mapFirebaseAuthErrorCode(error.code);
  }

  if (error is FirebaseException) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('permission-denied')) {
      return 'You do not have permission for this action.';
    }
    if (code.contains('unavailable') || message.contains('network')) {
      return 'Connection issue detected. Check your internet and try again.';
    }
    if (code.contains('deadline-exceeded')) {
      return 'The request took too long. Please try again.';
    }
    return fallback;
  }

  if (error is TimeoutException) {
    return 'The request took too long. Please try again.';
  }
  if (error is FormatException) {
    return 'Some information appears invalid. Please review and try again.';
  }

  return fallback;
}

class AppInlineFeedback extends StatelessWidget {
  const AppInlineFeedback({
    super.key,
    required this.message,
    this.type = AppFeedbackType.info,
  });

  final String message;
  final AppFeedbackType type;

  @override
  Widget build(BuildContext context) {
    final style = switch (type) {
      AppFeedbackType.success => (
        icon: Icons.check_circle_rounded,
        color: AppTheme.successGreen,
      ),
      AppFeedbackType.error => (
        icon: Icons.error_rounded,
        color: AppTheme.dangerRed,
      ),
      AppFeedbackType.info => (
        icon: Icons.info_rounded,
        color: AppTheme.secondaryAccentBlue,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: style.color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.color.withAlpha(140)),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDanger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDanger
                    ? AppTheme.dangerRed
                    : AppTheme.secondaryAccentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
