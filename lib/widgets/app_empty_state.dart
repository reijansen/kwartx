import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dark_card.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DarkCard(
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.navOverlay,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.glowOutlineBlue.withAlpha(80),
                ),
              ),
              child: Icon(icon, color: AppTheme.secondaryAccentBlue),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onActionPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
