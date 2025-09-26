import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quiz_question.dart';
import 'player_progress_provider.dart';

final quizQuestionsProvider = FutureProvider<List<QuizQuestion>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/quiz.json');
  final dynamic decoded = jsonDecode(jsonString);
  if (decoded is! List) {
    throw const FormatException(
      'Expected a list of quiz questions in quiz.json',
    );
  }

  return decoded
      .asMap()
      .entries
      .map(
        (entry) => QuizQuestion.fromJson(
          entry.value as Map<String, dynamic>,
          index: entry.key,
        ),
      )
      .toList(growable: false);
});

final remainingQuestionsProvider = Provider<AsyncValue<List<QuizQuestion>>>((
  ref,
) {
  final questions = ref.watch(quizQuestionsProvider);
  final progress = ref.watch(playerProgressProvider);

  return questions.when(
    data: (questionList) => progress.when(
      data: (progressValue) {
        final remaining = questionList
            .where(
              (question) =>
                  !progressValue.usedQuestionIds.contains(question.id),
            )
            .toList(growable: false);
        return AsyncData<List<QuizQuestion>>(remaining);
      },
      loading: AsyncLoading.new,
      error: AsyncError.new,
    ),
    loading: AsyncLoading.new,
    error: AsyncError.new,
  );
});
