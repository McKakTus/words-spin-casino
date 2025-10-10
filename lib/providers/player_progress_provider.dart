import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_progress.dart';
import 'storage_providers.dart';

const int _kStartingChips = 250;
const int _kDefaultBet = 12;
const int _kJackpotMax = 100;
const int _kJackpotChipReward = 200;
const Map<BoostType, int> _kJackpotBoostRewards = {
  BoostType.reSpin: 1,
  BoostType.revealLetter: 1,
  BoostType.swapTiles: 1,
  BoostType.timeFreeze: 1,
  BoostType.streakShield: 1,
};
const Map<BoostType, int> _kBoostStorePrices = {
  BoostType.reSpin: 60,
  BoostType.swapTiles: 75,
  BoostType.revealLetter: 90,
  BoostType.timeFreeze: 120,
  BoostType.streakShield: 150,
};

int boostStorePrice(BoostType type) => _kBoostStorePrices[type] ?? 100;

Map<BoostType, int> get boostStorePrices =>
    Map<BoostType, int>.unmodifiable(_kBoostStorePrices);

class LevelUpEvent {
  LevelUpEvent(this.level, this.label);

  final PlayerLevel level;
  final String label;
}

final levelUpEventProvider = StateProvider<LevelUpEvent?>((ref) => null);

class JackpotReward {
  const JackpotReward({required this.chips, required this.boosts});

  final int chips;
  final Map<BoostType, int> boosts;
}

final jackpotRewardProvider = StateProvider<JackpotReward?>((ref) => null);

class PlayerProgressNotifier extends AsyncNotifier<PlayerProgress> {
  late String _profileId;

  String _xpKey() => composeProfileKey(xpKeyBase, _profileId);
  String _chipsKey() => composeProfileKey(chipsKeyBase, _profileId);
  String _legacyCoinsKey() => composeProfileKey(coinsKeyBase, _profileId);
  String _usedWordsKey() => composeProfileKey(usedWordsKeyBase, _profileId);
  String _legacyUsedQuestionsKey() =>
      composeProfileKey(usedQuestionsKeyBase, _profileId);
  String _betKey() => composeProfileKey(currentBetKeyBase, _profileId);
  String _streakKey() => composeProfileKey(streakKeyBase, _profileId);
  String _jackpotKey() => composeProfileKey(jackpotKeyBase, _profileId);
  String _boostsKey() => composeProfileKey(boostsKeyBase, _profileId);

  @override
  Future<PlayerProgress> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final active = readActiveProfile(prefs);
    _profileId = active?.id ?? 'default';

    final xp = prefs.getInt(_xpKey()) ?? 0;

    final chips = prefs.getInt(_chipsKey()) ??
        prefs.getInt(_legacyCoinsKey()) ??
        _kStartingChips;
    if (!prefs.containsKey(_chipsKey())) {
      await prefs.setInt(_chipsKey(), chips);
    }

    final used = prefs.getStringList(_usedWordsKey()) ??
        prefs.getStringList(_legacyUsedQuestionsKey()) ??
        <String>[];

    final currentBet = prefs.getInt(_betKey()) ?? _kDefaultBet;
    final streak = prefs.getInt(_streakKey()) ?? 0;
    final jackpot = prefs.getInt(_jackpotKey()) ?? 0;
    final boostsRaw = prefs.getString(_boostsKey());
    final boostInventory = decodeBoostInventory(boostsRaw);

    return PlayerProgress(
      xp: xp,
      chips: chips,
      completedWordIds: used.toSet(),
      currentBet: currentBet,
      streak: streak,
      jackpotProgress: jackpot.clamp(0, _kJackpotMax).toInt(),
      boostInventory: boostInventory,
    );
  }

  Future<void> addXp(int amount) async {
    if (amount == 0) return;
    final current = await _ensureValue();
    final previousLevel = current.level;
    final updated = current.copyWith(
      xp: (current.xp + amount).clamp(0, 1 << 31).toInt(),
    );
    await _persist(updated);
    _maybeEmitLevelUp(previousLevel, updated.level);
    state = AsyncData(updated);
  }

  Future<void> addChips(int amount) async {
    if (amount == 0) return;
    final current = await _ensureValue();
    final updated = current.copyWith(
      chips: (current.chips + amount).clamp(0, 1 << 31).toInt(),
    );
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> addCoins(int amount) => addChips(amount);

  Future<void> spendChips(int amount) async {
    if (amount <= 0) return;
    final current = await _ensureValue();
    final remaining = (current.chips - amount).clamp(0, 1 << 31).toInt();
    final updated = current.copyWith(chips: remaining);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> setCurrentBet(int amount) async {
    if (amount <= 0) return;
    final current = await _ensureValue();
    final updated = current.copyWith(currentBet: amount);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> incrementStreak() async {
    final current = await _ensureValue();
    final updated = current.copyWith(streak: current.streak + 1);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> resetStreak() async {
    final current = await _ensureValue();
    if (current.streak == 0) return;
    final updated = current.copyWith(streak: 0);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> advanceJackpot(int amount) async {
    if (amount == 0) return;
    final current = await _ensureValue();
    final int total = current.jackpotProgress + amount;
    final bool triggered = total >= _kJackpotMax;
    final int remainder = triggered
        ? total % _kJackpotMax
        : total.clamp(0, _kJackpotMax);

    final inventory = Map<BoostType, int>.from(current.boostInventory);
    int chips = current.chips;
    JackpotReward? reward;

    if (triggered) {
      reward = JackpotReward(
        chips: _kJackpotChipReward,
        boosts: Map<BoostType, int>.unmodifiable(_kJackpotBoostRewards),
      );
      chips = (chips + reward.chips).clamp(0, 1 << 31).toInt();
      reward.boosts.forEach((type, count) {
        if (count <= 0) return;
        inventory[type] = (inventory[type] ?? 0) + count;
      });
    }

    final updated = current.copyWith(
      jackpotProgress: remainder,
      chips: chips,
      boostInventory: inventory,
    );
    await _persist(updated);
    state = AsyncData(updated);

    if (reward != null) {
      ref.read(jackpotRewardProvider.notifier).state = reward;
    }
  }

  Future<void> resetJackpot() async {
    final current = await _ensureValue();
    if (current.jackpotProgress == 0) return;
    final updated = current.copyWith(jackpotProgress: 0);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> grantBoost(BoostType type, [int count = 1]) async {
    if (count <= 0) return;
    final current = await _ensureValue();
    final inventory = Map<BoostType, int>.from(current.boostInventory);
    inventory[type] = (inventory[type] ?? 0) + count;
    final updated = current.copyWith(boostInventory: inventory);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<bool> consumeBoost(BoostType type) async {
    final current = await _ensureValue();
    final inventory = Map<BoostType, int>.from(current.boostInventory);
    final available = inventory[type] ?? 0;
    if (available <= 0) {
      return false;
    }
    inventory[type] = available - 1;
    if (inventory[type]! <= 0) {
      inventory.remove(type);
    }
    final updated = current.copyWith(boostInventory: inventory);
    await _persist(updated);
    state = AsyncData(updated);
    return true;
  }

  Future<bool> purchaseBoost(BoostType type, {int? priceOverride}) async {
    final int price = priceOverride ?? boostStorePrice(type);
    if (price <= 0) {
      return false;
    }
    final current = await _ensureValue();
    if (current.chips < price) {
      return false;
    }

    final updatedInventory = Map<BoostType, int>.from(current.boostInventory);
    updatedInventory[type] = (updatedInventory[type] ?? 0) + 1;
    final updated = current.copyWith(
      chips: current.chips - price,
      boostInventory: updatedInventory,
    );
    await _persist(updated);
    state = AsyncData(updated);
    return true;
  }

  Future<void> markQuestionUsed(String questionId) async {
    await markWordCompleted(questionId);
  }

  Future<void> markWordCompleted(String wordId) async {
    final current = await _ensureValue();
    if (current.completedWordIds.contains(wordId)) {
      return;
    }
    final updatedUsed = Set<String>.from(current.completedWordIds)..add(wordId);
    final updated = current.copyWith(completedWordIds: updatedUsed);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> resetProgress() async {
    final reset = PlayerProgress(
      xp: 0,
      chips: _kStartingChips,
      completedWordIds: <String>{},
      currentBet: _kDefaultBet,
      streak: 0,
      jackpotProgress: 0,
      boostInventory: <BoostType, int>{},
    );
    await _persist(reset);
    state = AsyncData(reset);
  }

  Future<PlayerProgress> _ensureValue() async {
    final current = state.valueOrNull;
    if (current != null) {
      return current;
    }
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final xp = prefs.getInt(_xpKey()) ?? 0;
    final chips = prefs.getInt(_chipsKey()) ??
        prefs.getInt(_legacyCoinsKey()) ??
        _kStartingChips;
    final used = prefs.getStringList(_usedWordsKey()) ??
        prefs.getStringList(_legacyUsedQuestionsKey()) ??
        <String>[];
    final currentBet = prefs.getInt(_betKey()) ?? _kDefaultBet;
    final streak = prefs.getInt(_streakKey()) ?? 0;
    final jackpot = prefs.getInt(_jackpotKey()) ?? 0;
    final boostsRaw = prefs.getString(_boostsKey());
    final boostInventory = decodeBoostInventory(boostsRaw);
    final progress = PlayerProgress(
      xp: xp,
      chips: chips,
      completedWordIds: used.toSet(),
      currentBet: currentBet,
      streak: streak,
      jackpotProgress: jackpot.clamp(0, _kJackpotMax).toInt(),
      boostInventory: boostInventory,
    );
    state = AsyncData(progress);
    return progress;
  }

  Future<void> _persist(PlayerProgress progress) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_xpKey(), progress.xp);
    await prefs.setInt(_chipsKey(), progress.chips);
    await prefs.setInt(_betKey(), progress.currentBet);
    await prefs.setInt(_streakKey(), progress.streak);
    await prefs.setInt(_jackpotKey(), progress.jackpotProgress);
    await prefs.setString(_boostsKey(), encodeBoostInventory(progress.boostInventory));
    await prefs.setStringList(
      _usedWordsKey(),
      progress.completedWordIds.toList(),
    );
    await prefs.remove(_legacyUsedQuestionsKey());
    await prefs.remove(_legacyCoinsKey());
  }

  void _maybeEmitLevelUp(PlayerLevel previous, PlayerLevel current) {
    if (current.index <= previous.index) {
      return;
    }
    ref.read(levelUpEventProvider.notifier).state =
        LevelUpEvent(current, _levelLabel(current));
  }

  String _levelLabel(PlayerLevel level) {
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
}

final playerProgressProvider =
    AsyncNotifierProvider<PlayerProgressNotifier, PlayerProgress>(
      PlayerProgressNotifier.new,
    );
