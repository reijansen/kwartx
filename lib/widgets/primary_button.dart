import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_loading_indicator.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryAccentBlue, AppTheme.secondaryAccentBlue],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x662D7DFF),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const AppLoadingIndicator(size: 20, strokeWidth: 2)
            : Text(label),
      ),
    );
  }
}
