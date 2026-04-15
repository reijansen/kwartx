import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return HomeScreen(authService: _authService);
        }

        if (_showSignUp) {
          return SignUpScreen(
            authService: _authService,
            onNavigateToSignIn: () {
              setState(() {
                _showSignUp = false;
              });
            },
          );
        }

        return SignInScreen(
          authService: _authService,
          onNavigateToSignUp: () {
            setState(() {
              _showSignUp = true;
            });
          },
        );
      },
    );
  }
}
