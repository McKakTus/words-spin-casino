import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wheel_segment.dart';

final wheelConfigProvider = Provider<WheelConfig>((ref) {
  return WheelConfig(
    spinCost: 12,
    segments: [
      WheelSegmentConfig(
        id: WheelSegmentId.standard,
        displayName: 'Standard',
        description: 'Balanced payout and classic challenge.',
        rewardMultiplier: 1.0,
        penaltyMultiplier: 1.0,
        baseDifficulty: 'medium',
        modifiers: const [],
        weight: 1,
      ),
      WheelSegmentConfig(
        id: WheelSegmentId.highStakes,
        displayName: 'High Stakes',
        description: 'Bigger rewards and higher penalties.',
        rewardMultiplier: 2.0,
        penaltyMultiplier: 1.5,
        baseDifficulty: 'hard',
        modifiers: const [WheelModifierType.extraRewardMultiplier],
        weight: 1,
      ),
      WheelSegmentConfig(
        id: WheelSegmentId.quickDraw,
        displayName: 'Quick Draw',
        description: 'Short word, strict timer.',
        rewardMultiplier: 1.25,
        penaltyMultiplier: 1.0,
        baseDifficulty: 'easy',
        modifiers: const [WheelModifierType.timeLimit],
        weight: 1,
      ),
      WheelSegmentConfig(
        id: WheelSegmentId.mystery,
        displayName: 'Mystery',
        description: 'Random modifiers and jackpot boost.',
        rewardMultiplier: 1.5,
        penaltyMultiplier: 1.0,
        baseDifficulty: 'medium',
        modifiers: const [
          WheelModifierType.randomizer,
          WheelModifierType.jackpotMeter,
          WheelModifierType.wildcardChoice,
        ],
        weight: 1,
      ),
      WheelSegmentConfig(
        id: WheelSegmentId.luckyLetters,
        displayName: 'Lucky Letters',
        description: 'Extra vowels and bonus hint.',
        rewardMultiplier: 1.0,
        penaltyMultiplier: 0.9,
        baseDifficulty: 'easy',
        modifiers: const [WheelModifierType.bonusVowels],
        weight: 1,
      ),
      WheelSegmentConfig(
        id: WheelSegmentId.doubleDown,
        displayName: 'Double Down',
        description: 'Two words for double reward.',
        rewardMultiplier: 2.5,
        penaltyMultiplier: 1.0,
        baseDifficulty: 'medium',
        modifiers: const [
          WheelModifierType.doubleDown,
          WheelModifierType.optionalRisk,
        ],
        weight: 1,
      ),
      WheelSegmentConfig(
        id: WheelSegmentId.burningTiles,
        displayName: 'Burning Tiles',
        description: 'Tiles fade away over time.',
        rewardMultiplier: 1.4,
        penaltyMultiplier: 1.1,
        baseDifficulty: 'medium',
        modifiers: const [WheelModifierType.burningTiles],
        weight: 1,
      ),
      WheelSegmentConfig(
        id: WheelSegmentId.jackpot,
        displayName: 'Jackpot',
        description: 'Build the mega jackpot.',
        rewardMultiplier: 2.0,
        penaltyMultiplier: 1.0,
        baseDifficulty: 'medium',
        modifiers: const [WheelModifierType.jackpotMeter],
        weight: 1,
      ),
    ],
  );
});
