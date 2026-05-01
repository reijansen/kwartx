import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dark_card.dart';
import 'radial_hero.dart';

class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    this.onTap,
    this.heroTag,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = appAnimationsEnabled(context);
    final tag = heroTag;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: DarkCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ExpenseIconHero(
              enabled: enabled,
              heroTag: tag,
              icon: icon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              amount,
              style: textTheme.titleMedium?.copyWith(
                color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseIconHero extends StatelessWidget {
  const _ExpenseIconHero({
    required this.enabled,
    required this.heroTag,
    required this.icon,
  });

  final bool enabled;
  final String? heroTag;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: AppTheme.textSecondary),
    );

    if (heroTag == null || heroTag!.trim().isEmpty) {
      return iconBox;
    }

    return RadialHero(
      tag: heroTag!,
      enabled: enabled,
      maxRadius: 23,
      child: iconBox,
    );
  }
}
