import '../models/player_progress.dart';

class LevelProgressInfo {
  const LevelProgressInfo({
    required this.level,
    required this.progressRatio,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.nextLevelLabel,
  });

  final PlayerLevel level;
  final double progressRatio;
  final int xpIntoLevel;
  final int? xpToNextLevel;
  final String nextLevelLabel;

  static LevelProgressInfo from(PlayerProgress progress) {
    final PlayerLevel level = progress.level;
    final int base = _baseXpFor(level);
    final int? next = _nextXpFor(level);
    final int xpIntoLevel = progress.xp - base;
    final int? xpSpan = next != null ? next - base : null;
    final double ratio = xpSpan == null || xpSpan <= 0
        ? 1.0
        : (xpIntoLevel / xpSpan).clamp(0.0, 1.0);
    final int? xpToNextLevel =
        next != null ? (next - progress.xp).clamp(0, next) : null;

    return LevelProgressInfo(
      level: level,
      progressRatio: ratio,
      xpIntoLevel: xpIntoLevel,
      xpToNextLevel: xpToNextLevel,
      nextLevelLabel: _labelForNext(level),
    );
  }

  static int _baseXpFor(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 0;
      case PlayerLevel.learner:
        return 50;
      case PlayerLevel.intermediate:
        return 150;
      case PlayerLevel.advanced:
        return 300;
      case PlayerLevel.pro:
        return 500;
    }
  }

  static int? _nextXpFor(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 50;
      case PlayerLevel.learner:
        return 150;
      case PlayerLevel.intermediate:
        return 300;
      case PlayerLevel.advanced:
        return 500;
      case PlayerLevel.pro:
        return null;
    }
  }

  static String _labelForNext(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 'Learner';
      case PlayerLevel.learner:
        return 'Intermediate';
      case PlayerLevel.intermediate:
        return 'Advanced';
      case PlayerLevel.advanced:
        return 'Pro';
      case PlayerLevel.pro:
        return 'Max';
    }
  }
}
