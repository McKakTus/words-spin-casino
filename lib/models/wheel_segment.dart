enum WheelSegmentId {
  standard,
  highStakes,
  quickDraw,
  mystery,
  luckyLetters,
  doubleDown,
  burningTiles,
  jackpot,
}

enum WheelModifierType {
  timeLimit,
  extraRewardMultiplier,
  extraPenaltyMultiplier,
  bonusVowels,
  burningTiles,
  doubleDown,
  randomizer,
  jackpotMeter,
  optionalRisk,
  wildcardChoice,
}

class WheelSegmentConfig {
  const WheelSegmentConfig({
    required this.id,
    required this.displayName,
    required this.description,
    required this.rewardMultiplier,
    required this.penaltyMultiplier,
    required this.baseDifficulty,
    required this.modifiers,
    this.iconAsset,
    this.weight,
  });

  final WheelSegmentId id;
  final String displayName;
  final String description;
  final double rewardMultiplier;
  final double penaltyMultiplier;
  final String baseDifficulty;
  final List<WheelModifierType> modifiers;
  final String? iconAsset;
  final int? weight;
}

class WheelConfig {
  const WheelConfig({required this.segments, required this.spinCost});

  final List<WheelSegmentConfig> segments;
  final int spinCost;
}
