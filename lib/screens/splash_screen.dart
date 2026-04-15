import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'auth_gate_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AuthGateScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 30,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wallet_rounded,
                    size: 42,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 28),
                Text('KwartX', style: textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(
                  'Split expenses simply with the people around you.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
