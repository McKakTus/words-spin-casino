class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    this.category,
    this.difficulty,
  });

  final String id;
  final String question;
  final List<String> options;
  final String answer;
  final String? category;
  final String? difficulty;

  factory QuizQuestion.fromJson(
    Map<String, dynamic> json, {
    required int index,
  }) {
    final options = List<String>.from(json['options'] as List<dynamic>);
    return QuizQuestion(
      id: json['id'] as String? ?? 'q$index',
      question: json['question'] as String? ?? '',
      options: options,
      answer: json['answer'] as String? ?? '',
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'question': question,
      'options': options,
      'answer': answer,
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }
}
