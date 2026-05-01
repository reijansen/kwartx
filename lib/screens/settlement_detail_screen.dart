import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/settlement_view_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dark_card.dart';
import '../widgets/radial_hero.dart';

class SettlementDetailScreen extends StatelessWidget {
  const SettlementDetailScreen({
    super.key,
    required this.settlement,
    required this.heroTag,
  });

  final SettlementViewModel settlement;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final enabled = appAnimationsEnabled(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDebtor = currentUserId.isNotEmpty && settlement.fromUserId == currentUserId;
    final statusLabel = isDebtor ? 'Pending payment' : 'Awaiting payment';
    final accent = isDebtor ? AppTheme.dangerRed : AppTheme.successGreen;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text('Settlement', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 8),
              DarkCard(
                radius: 22,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  children: [
                    RadialHero(
                      tag: heroTag,
                      enabled: enabled,
                      maxRadius: 56,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: accent.withAlpha(22),
                        child: Icon(
                          isDebtor ? Icons.call_made_rounded : Icons.call_received_rounded,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Formatters.currency(settlement.amountCents / 100),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _Line(label: 'From', value: settlement.fromName),
                    const SizedBox(height: 6),
                    _Line(label: 'To', value: settlement.toName),
                    const SizedBox(height: 6),
                    _Line(label: 'Status', value: statusLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

