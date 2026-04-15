import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dark_card.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.topLabel,
    this.showBackButton = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? topLabel;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xAA0E1A2B),
                            border: Border.all(
                              color: AppTheme.glowOutlineBlue.withAlpha(180),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x442D7DFF),
                                blurRadius: 26,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppTheme.secondaryAccentBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (topLabel != null) ...[
                          Text(
                            topLabel!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryAccentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(title, style: textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(subtitle, style: textTheme.bodyMedium),
                        const SizedBox(height: 22),
                        DarkCard(
                          padding: const EdgeInsets.all(16),
                          radius: 20,
                          child: child,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
