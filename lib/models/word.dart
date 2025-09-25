class Word {
  const Word({
    required this.word,
    required this.translation,
    required this.example,
    required this.exampleTranslation,
  });

  final String word;
  final String translation;
  final String example;
  final String exampleTranslation;

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      word: json['word'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      example: json['example'] as String? ?? '',
      exampleTranslation: json['example_translation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'word': word,
      'translation': translation,
      'example': example,
      'example_translation': exampleTranslation,
    };
  }
}
