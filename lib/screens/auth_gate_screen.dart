import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _authService = AuthService();
  bool _showSignUp = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.screenGradient),
              child: Center(child: AppLoadingIndicator()),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return AnimatedSwitcher(
            duration: Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: HomeScreen(
              key: const ValueKey('home_screen'),
              authService: _authService,
            ),
          );
        }

        if (_showSignUp) {
          return AnimatedSwitcher(
            duration: Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: SignUpScreen(
              key: const ValueKey('sign_up_screen'),
              authService: _authService,
              onNavigateToSignIn: () {
                setState(() {
                  _showSignUp = false;
                });
              },
            ),
          );
        }

        return AnimatedSwitcher(
          duration: Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: SignInScreen(
            key: const ValueKey('sign_in_screen'),
            authService: _authService,
            onNavigateToSignUp: () {
              setState(() {
                _showSignUp = true;
              });
            },
          ),
        );
      },
    );
  }
}
