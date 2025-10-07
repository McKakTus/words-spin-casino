import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_challenge.dart';
import 'player_progress_provider.dart';

/// Loads all word challenges bundled inside [assets/words.json].
final wordChallengesProvider = FutureProvider<List<WordChallenge>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/words.json');
  final dynamic decoded = jsonDecode(jsonString);
  if (decoded is! List) {
    throw const FormatException('Expected a list of word challenges');
  }

  return decoded
      .asMap()
      .entries
      .map(
        (entry) => WordChallenge.fromJson(
          entry.value as Map<String, dynamic>,
          index: entry.key,
        ),
      )
      .toList(growable: false);
});

/// Exposes the list of challenges the player has not yet completed.
final remainingWordChallengesProvider = Provider<AsyncValue<List<WordChallenge>>>(
  (ref) {
    final challenges = ref.watch(wordChallengesProvider);
    final progress = ref.watch(playerProgressProvider);

    return challenges.when(
      data: (allChallenges) => progress.when(
        data: (progressValue) {
          final remaining = allChallenges
              .where((challenge) =>
                  !progressValue.completedWordIds.contains(challenge.id))
              .toList(growable: false);
          return AsyncData<List<WordChallenge>>(remaining);
        },
        loading: AsyncLoading.new,
        error: AsyncError.new,
      ),
      loading: AsyncLoading.new,
      error: AsyncError.new,
    );
  },
);
