import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_nav_bar.dart';
import 'analytics_screen.dart';
import 'expense_form_screen.dart';
import 'home_screen.dart';
import 'invite_roommate_screen.dart';
import 'profile_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  Future<void> _openAddExpense() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ExpenseFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(authService: widget.authService),
      const AnalyticsScreen(),
      const InviteRoommateScreen(initialTabIndex: 2),
      ProfileScreen(authService: widget.authService),
    ];

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey('tab_$_index'),
              child: pages[_index],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.heroGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3310B981),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _openAddExpense,
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                  FloatingNavBar(
                    currentIndex: _index,
                    onTap: (value) => setState(() => _index = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
