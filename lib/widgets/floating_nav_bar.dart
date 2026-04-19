import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = const [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.bar_chart_rounded, label: 'Analytics'),
      (icon: Icons.people_alt_rounded, label: 'Roommates'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final selected = index == currentIndex;
          final item = items[index];
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.secondaryAccentBlue.withAlpha(22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: selected
                          ? AppTheme.secondaryAccentBlue
                          : AppTheme.mutedText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: selected
                                ? AppTheme.secondaryAccentBlue
                                : AppTheme.mutedText,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
