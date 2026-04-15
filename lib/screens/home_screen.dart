import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import 'expense_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.authService.signOut();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _openExpenseForm(String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ExpenseFormScreen(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final email = widget.authService.currentUser?.email ?? 'user@kwartx.app';
    final expenseItems = const [
      ('Team dinner', '3 people - Yesterday', '- \$84.20'),
      ('Groceries', 'Apartment - 2 days ago', '- \$56.75'),
      ('Ride share', 'Shared ride - Monday', '- \$14.90'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('KwartX'),
        actions: [
          IconButton(
            onPressed: _isSigningOut ? null : _handleSignOut,
            tooltip: 'Logout',
            icon: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textPrimary,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.navOverlay,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.glowOutlineBlue.withAlpha(170),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DarkCard(
                radius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared expenses',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('This month', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(
                      '\$1,284.60',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Quick actions', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Add',
                    onTap: () => _openExpenseForm('Add Expense'),
                  ),
                  _QuickAction(
                    icon: Icons.call_split_rounded,
                    label: 'Split',
                    onTap: () => _openExpenseForm('Split Bill'),
                  ),
                  _QuickAction(
                    icon: Icons.bar_chart_rounded,
                    label: 'Summary',
                    onTap: () => _openExpenseForm('Summary'),
                  ),
                  _QuickAction(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    onTap: () => _openExpenseForm('More Actions'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Recent expenses', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              ...expenseItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DarkCard(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$1, style: textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                item.$2,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.$3,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.navOverlay,
                border: Border.all(
                  color: AppTheme.glowOutlineBlue.withAlpha(140),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x442D7DFF),
                    blurRadius: 16,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.secondaryAccentBlue),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
