import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey('tab_$_index'),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: FloatingNavBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          onAddPressed: _openAddExpense,
        ),
      ),
    );
  }
}
