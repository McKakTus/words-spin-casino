import 'dart:convert';

import 'package:flutter/foundation.dart';

enum PlayerLevel { beginner, learner, intermediate, advanced, pro }

enum BoostType { reSpin, revealLetter, swapTiles, timeFreeze, streakShield }

class PlayerProgress {
  const PlayerProgress({
    required this.xp,
    required this.chips,
    required this.completedWordIds,
    required this.currentBet,
    required this.streak,
    required this.jackpotProgress,
    required this.boostInventory,
  });

  final int xp;
  final int chips;
  final Set<String> completedWordIds;
  final int currentBet;
  final int streak;
  final int jackpotProgress; // 0-100 inclusive
  final Map<BoostType, int> boostInventory;

  /// Backwards-compatibility getter while legacy quiz code is still in place.
  Set<String> get usedQuestionIds => completedWordIds;

  /// Legacy accessor for code still referencing coins.
  @Deprecated('Use chips instead of coins')
  int get coins => chips;

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

  PlayerProgress copyWith({
    int? xp,
    int? chips,
    Set<String>? completedWordIds,
    Set<String>? usedQuestionIds,
    int? currentBet,
    int? streak,
    int? jackpotProgress,
    Map<BoostType, int>? boostInventory,
  }) {
    return PlayerProgress(
      xp: xp ?? this.xp,
      chips: chips ?? this.chips,
      completedWordIds:
          completedWordIds ?? usedQuestionIds ?? this.completedWordIds,
      currentBet: currentBet ?? this.currentBet,
      streak: streak ?? this.streak,
      jackpotProgress: jackpotProgress ?? this.jackpotProgress,
      boostInventory: boostInventory ?? this.boostInventory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerProgress &&
        other.xp == xp &&
        other.chips == chips &&
        other.currentBet == currentBet &&
        other.streak == streak &&
        other.jackpotProgress == jackpotProgress &&
        mapEquals(other.boostInventory, boostInventory) &&
        setEquals(other.completedWordIds, completedWordIds);
  }

  @override
  int get hashCode => Object.hash(
        xp,
        chips,
        currentBet,
        streak,
        jackpotProgress,
        Object.hashAll(
          boostInventory.entries
              .map((entry) => Object.hash(entry.key, entry.value)),
        ),
        Object.hashAll(completedWordIds),
      );
}

Map<BoostType, int> decodeBoostInventory(String? serialized) {
  if (serialized == null || serialized.isEmpty) {
    return <BoostType, int>{};
  }
  try {
    final dynamic decoded = jsonDecode(serialized);
    if (decoded is! Map<String, dynamic>) {
      return <BoostType, int>{};
    }
    final result = <BoostType, int>{};
    decoded.forEach((key, value) {
      final boost = BoostType.values.firstWhere(
        (type) => type.name == key,
        orElse: () => BoostType.reSpin,
      );
      final count = value is int ? value : int.tryParse(value.toString()) ?? 0;
      if (count > 0) {
        result[boost] = count;
      }
    });
    return result;
  } catch (_) {
    return <BoostType, int>{};
  }
}

String encodeBoostInventory(Map<BoostType, int> inventory) {
  final mapped = inventory.map((key, value) => MapEntry(key.name, value));
  return jsonEncode(mapped);
}
