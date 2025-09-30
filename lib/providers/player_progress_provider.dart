import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_progress.dart';
import 'storage_providers.dart';

class PlayerProgressNotifier extends AsyncNotifier<PlayerProgress> {
  late String _profileId;

  String _xpKey() => composeProfileKey(xpKeyBase, _profileId);
  String _coinsKey() => composeProfileKey(coinsKeyBase, _profileId);
  String _usedQuestionsKey() =>
      composeProfileKey(usedQuestionsKeyBase, _profileId);

  @override
  Future<PlayerProgress> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final active = readActiveProfile(prefs);
    _profileId = active?.id ?? 'default';

    final xp = prefs.getInt(_xpKey()) ?? 0;
    final coins = prefs.getInt(_coinsKey()) ?? 0;
    final used = prefs.getStringList(_usedQuestionsKey()) ?? <String>[];

    return PlayerProgress(xp: xp, coins: coins, usedQuestionIds: used.toSet());
  }

  Future<void> addXp(int amount) async {
    final current = await _ensureValue();
    final updated = current.copyWith(xp: current.xp + amount);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> addCoins(int amount) async {
    final current = await _ensureValue();
    final updated = current.copyWith(coins: current.coins + amount);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> markQuestionUsed(String questionId) async {
    final current = await _ensureValue();
    if (current.usedQuestionIds.contains(questionId)) {
      return;
    }
    final updatedUsed = Set<String>.from(current.usedQuestionIds)
      ..add(questionId);
    final updated = current.copyWith(usedQuestionIds: updatedUsed);
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> resetProgress() async {
    final reset = PlayerProgress(xp: 0, coins: 0, usedQuestionIds: <String>{});
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
    final coins = prefs.getInt(_coinsKey()) ?? 0;
    final used = prefs.getStringList(_usedQuestionsKey()) ?? <String>[];
    return PlayerProgress(xp: xp, coins: coins, usedQuestionIds: used.toSet());
  }

  Future<void> _persist(PlayerProgress progress) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_xpKey(), progress.xp);
    await prefs.setInt(_coinsKey(), progress.coins);
    await prefs.setStringList(
      _usedQuestionsKey(),
      progress.usedQuestionIds.toList(),
    );
  }
}

final playerProgressProvider =
    AsyncNotifierProvider<PlayerProgressNotifier, PlayerProgress>(
      PlayerProgressNotifier.new,
    );
