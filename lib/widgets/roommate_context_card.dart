import 'package:flutter/material.dart';

import '../models/roommate_model.dart';
import '../screens/roommate_detail_screen.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';
import 'radial_hero.dart';

class RoommateContextCard extends StatelessWidget {
  const RoommateContextCard({
    super.key,
    required this.roommates,
    required this.onInvitePressed,
  });

  final List<RoommateModel> roommates;
  final VoidCallback onInvitePressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (roommates.isEmpty) {
      return DarkCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are not sharing with anyone yet', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Invite roommates so KwartX can split bills and calculate who owes who.',
              style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onInvitePressed,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Invite roommates'),
            ),
          ],
        ),
      );
    }

    return DarkCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${roommates.length} roommate${roommates.length == 1 ? '' : 's'} in your household',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roommates.take(6).map((roommate) {
              final initials = _initials(roommate.displayName);
              final heroTag = 'hero_roommate_${roommate.id}';
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppTheme.secondaryAccentBlue.withAlpha(45),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final enabled = appAnimationsEnabled(context);
                      Navigator.of(context).push(
                        AppRadialPageRoute<void>(
                          builder: (_) => RoommateDetailScreen(
                            roommate: roommate,
                            heroTag: heroTag,
                          ),
                          duration: enabled
                              ? const Duration(milliseconds: 460)
                              : Duration.zero,
                        ),
                      );
                    },
                    child: RadialHero(
                      tag: heroTag,
                      enabled: appAnimationsEnabled(context),
                      maxRadius: 26,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                label: Text(
                  roommate.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((it) => it.isNotEmpty);
    final letters = parts.take(2).map((it) => it[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}
