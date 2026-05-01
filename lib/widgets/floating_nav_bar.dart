import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'radial_hero.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF2A201B),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(icon: Icons.home_rounded, selected: currentIndex == 0, onPressed: () => onTap(0)),
          _buildNavItem(icon: Icons.bar_chart_rounded, selected: currentIndex == 1, onPressed: () => onTap(1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: RadialHero(
                tag: 'hero_fab_add',
                enabled: appAnimationsEnabled(context),
                maxRadius: 28,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.heroGradient,
                  ),
                  child: IconButton(
                    onPressed: onAddPressed,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          _buildNavItem(icon: Icons.people_alt_rounded, selected: currentIndex == 2, onPressed: () => onTap(2)),
          _buildNavItem(icon: Icons.person_rounded, selected: currentIndex == 3, onPressed: () => onTap(3)),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Icon(
            icon,
            size: 20,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
