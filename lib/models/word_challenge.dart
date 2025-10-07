import 'dart:math';

/// Data model describing a single word-based challenge that the player
/// needs to solve.
class WordChallenge {
  WordChallenge({
    required String id,
    required String answer,
    required String category,
    String? difficulty,
    String? hint,
    List<String> extraLetters = const <String>[],
    List<String>? comboAnswers,
    List<String>? wildcardCategories,
  })  : assert(answer.trim().isNotEmpty, 'answer cannot be empty'),
        id = id.trim(),
        answer = _normalize(answer),
        category = category.trim().isEmpty ? 'Word' : category.trim(),
        difficulty = _normalizeOptionalLabel(difficulty),
        hint = _normalizeHint(hint),
        extraLetters = _normalizeLetters(extraLetters),
        comboAnswers = _normalizeCombo(comboAnswers),
        wildcardCategories = _normalizeCategories(wildcardCategories),
        letterSlots = _buildLetterSlots(_normalize(answer));

  /// Unique identifier used for persistence and analytics.
  final String id;

  /// Canonical answer in uppercase characters.
  final String answer;

  /// High-level grouping used when rendering the wheel segments.
  final String category;

  /// Optional difficulty label ("easy", "medium", "hard", ...).
  final String? difficulty;

  /// Optional hint that can be surfaced inside the word quiz screen.
  final String? hint;

  /// Optional pool of extra letters to mix with the solution letters.
  final List<String> extraLetters;
  final List<String>? comboAnswers;
  final List<String>? wildcardCategories;

  /// Letter slots describing the exact character and position that
  /// must be filled to solve the challenge.
  final List<WordLetterSlot> letterSlots;

  /// All characters that can be used to render selectable tiles. This includes
  /// the solution characters and any additional distractors.
  List<WordTile> buildTiles({Random? random, bool shuffle = true}) {
    final tiles = <WordTile>[
      for (final slot in letterSlots)
        WordTile(
          id: '${slot.index}_${slot.character}',
          character: slot.character,
          slotIndex: slot.index,
          isSolution: true,
        ),
      for (var i = 0; i < extraLetters.length; i++)
        WordTile(
          id: 'extra_${i}_${extraLetters[i]}',
          character: _normalize(extraLetters[i]),
          slotIndex: null,
          isSolution: false,
        ),
    ];

    if (shuffle) {
      tiles.shuffle(random ?? Random());
    }

    return tiles;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'answer': answer,
      'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (hint != null) 'hint': hint,
      if (extraLetters.isNotEmpty) 'extraLetters': extraLetters,
      if (comboAnswers != null) 'comboAnswers': comboAnswers,
      if (wildcardCategories != null) 'wildcardCategories': wildcardCategories,
    };
  }

  factory WordChallenge.fromJson(Map<String, dynamic> json, {required int index}) {
    final rawAnswer = json['answer'] as String? ?? '';
    if (rawAnswer.trim().isEmpty) {
      throw ArgumentError('Word challenge at index $index is missing an answer');
    }

    final rawId = json['id'] as String?;
    final parsedId =
        (rawId == null || rawId.trim().isEmpty) ? 'w$index' : rawId.trim();

    return WordChallenge(
      id: parsedId,
      answer: rawAnswer,
      category: json['category'] as String? ?? 'Word',
      difficulty: json['difficulty'] as String?,
      hint: json['hint'] as String?,
      extraLetters: _readExtraLetters(json['extraLetters']),
      comboAnswers: _readComboAnswers(json['comboAnswers']),
      wildcardCategories: _readWildcardCategories(json['wildcardCategories']),
    );
  }

  static List<WordLetterSlot> _buildLetterSlots(String answer) {
    final normalizedAnswer = _normalize(answer);
    final slots = <WordLetterSlot>[];

    for (var i = 0; i < normalizedAnswer.length; i++) {
      final char = normalizedAnswer[i];
      if (!_allowedCharacters.contains(char)) {
        throw ArgumentError('Unsupported character "$char" in answer "$answer"');
      }
      slots.add(WordLetterSlot(index: i, character: char));
    }
    return List.unmodifiable(slots);
  }

  static List<String> _readExtraLetters(dynamic value) {
    if (value is List) {
      final letters = value
          .whereType<String>()
          .map(_normalize)
          .where((letter) => letter.isNotEmpty)
          .toList(growable: false);
      return _normalizeLetters(letters);
    }
    return const <String>[];
  }

  static String _normalize(String value) => value.trim().toUpperCase();

  static String? _normalizeOptionalLabel(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _normalizeHint(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _normalizeLetters(List<String> letters) {
    return List<String>.unmodifiable(
      letters
          .map(_normalize)
          .where((letter) => letter.isNotEmpty && _allowedCharacters.contains(letter)),
    );
  }

  static List<String>? _normalizeCombo(List<String>? combo) {
    if (combo == null || combo.isEmpty) return null;
    final normalized = combo
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return normalized.isEmpty ? null : List<String>.unmodifiable(normalized);
  }

  static List<String>? _normalizeCategories(List<String>? categories) {
    if (categories == null || categories.isEmpty) return null;
    final normalized = categories
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return normalized.isEmpty ? null : List<String>.unmodifiable(normalized);
  }

  WordChallenge copyWith({
    String? id,
    String? answer,
    String? category,
    String? difficulty,
    String? hint,
    List<String>? extraLetters,
    List<String>? comboAnswers,
    List<String>? wildcardCategories,
  }) {
    return WordChallenge(
      id: id ?? this.id,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      hint: hint ?? this.hint,
      extraLetters: extraLetters ?? this.extraLetters,
      comboAnswers: comboAnswers ?? this.comboAnswers,
      wildcardCategories: wildcardCategories ?? this.wildcardCategories,
    );
  }
}

List<String>? _readComboAnswers(dynamic value) {
  if (value is List) {
    final combo = value
        .whereType<String>()
        .map((str) => str.trim())
        .where((str) => str.isNotEmpty)
        .toList(growable: false);
    return combo.isEmpty ? null : combo;
  }
  return null;
}

List<String>? _readWildcardCategories(dynamic value) {
  if (value is List) {
    final categories = value
        .whereType<String>()
        .map((str) => str.trim())
        .where((str) => str.isNotEmpty)
        .toList(growable: false);
    return categories.isEmpty ? null : categories;
  }
  return null;
}

/// Represents a specific letter and its target slot in the solution word.
class WordLetterSlot {
  const WordLetterSlot({required this.index, required this.character});

  final int index;
  final String character;
}

/// Describes a tile (button) that can be tapped by the player. Solution tiles
/// point to a concrete slot index while distractors do not.
class WordTile {
  const WordTile({
    required this.id,
    required this.character,
    required this.isSolution,
    this.slotIndex,
  });

  final String id;
  final String character;
  final bool isSolution;
  final int? slotIndex;
}

const Set<String> _allowedCharacters = <String>{
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
};
