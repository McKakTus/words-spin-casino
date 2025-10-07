import 'package:flutter/material.dart';

import '../models/player_progress.dart';
import '../providers/player_progress_provider.dart';

class BoostInfo {
  const BoostInfo({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final BoostType type;
  final String label;
  final String description;
  final IconData icon;
  final Color accent;
}

class BoostCatalog {
  static BoostInfo info(BoostType type) {
    switch (type) {
      case BoostType.reSpin:
        return const BoostInfo(
          type: BoostType.reSpin,
          label: 'Shuffle',
          description: 'Returns placed letters and refreshes the tile tray.',
          icon: Icons.shuffle_rounded,
          accent: Color(0xFF6DD3FF),
        );
      case BoostType.revealLetter:
        return const BoostInfo(
          type: BoostType.revealLetter,
          label: 'Reveal',
          description: 'Fills one empty slot with the correct letter.',
          icon: Icons.lightbulb_outline,
          accent: Color(0xFFFFF066),
        );
      case BoostType.swapTiles:
        return const BoostInfo(
          type: BoostType.swapTiles,
          label: 'Swap',
          description: 'Swap the positions of two unused tiles.',
          icon: Icons.swap_horiz_rounded,
          accent: Color(0xFF00F5A0),
        );
      case BoostType.timeFreeze:
        return const BoostInfo(
          type: BoostType.timeFreeze,
          label: 'Freeze',
          description: 'Pauses the countdown and burning tiles for eight seconds.',
          icon: Icons.ac_unit_rounded,
          accent: Color(0xFF4C6FFF),
        );
      case BoostType.streakShield:
        return const BoostInfo(
          type: BoostType.streakShield,
          label: 'Shield',
          description: 'Protects your streak and wager from the next failure.',
          icon: Icons.shield_outlined,
          accent: Color(0xFFFF6E6E),
        );
    }
  }

  static int price(BoostType type) => boostStorePrice(type);

  static List<BoostInfo> all() =>
      BoostType.values.map((type) => BoostCatalog.info(type)).toList(growable: false);
}
