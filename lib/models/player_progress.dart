import 'package:flutter/foundation.dart';

enum PlayerLevel { beginner, learner, intermediate, advanced, pro }

class PlayerProgress {
  const PlayerProgress({
    required this.xp,
    required this.coins,
    required this.usedQuestionIds,
  });

  final int xp;
  final int coins;
  final Set<String> usedQuestionIds;

  PlayerLevel get level {
    if (xp >= 500) return PlayerLevel.pro;
    if (xp >= 300) return PlayerLevel.advanced;
    if (xp >= 150) return PlayerLevel.intermediate;
    if (xp >= 50) return PlayerLevel.learner;
    return PlayerLevel.beginner;
  }

  String get levelLabel {
    switch (level) {
      case PlayerLevel.beginner:
        return 'Beginner';
      case PlayerLevel.learner:
        return 'Learner';
      case PlayerLevel.intermediate:
        return 'Intermediate';
      case PlayerLevel.advanced:
        return 'Advanced';
      case PlayerLevel.pro:
        return 'Pro';
    }
  }

  PlayerProgress copyWith({int? xp, int? coins, Set<String>? usedQuestionIds}) {
    return PlayerProgress(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      usedQuestionIds: usedQuestionIds ?? this.usedQuestionIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerProgress &&
        other.xp == xp &&
        other.coins == coins &&
        setEquals(other.usedQuestionIds, usedQuestionIds);
  }

  @override
  int get hashCode => Object.hash(xp, coins, Object.hashAll(usedQuestionIds));
}
