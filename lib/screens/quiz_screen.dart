import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quiz_question.dart';
import '../providers/player_progress_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.question});

  final QuizQuestion question;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  static const int _xpReward = 25;
  static const int _coinReward = 5;

  late final ConfettiController _confettiController;
  String? _selectedOption;
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050505), Color(0xFF171717)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Quiz Challenge',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232323),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        widget.question.category?.toUpperCase() ?? 'QUIZ',
                        style: const TextStyle(
                          color: Color(0xFFF6D736),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.question.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: ListView.separated(
                        itemCount: widget.question.options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final option = widget.question.options[index];
                          return _AnswerOption(
                            optionText: option,
                            index: index,
                            isSelected: _selectedOption == option,
                            isCorrect:
                                _answered && option == widget.question.answer,
                            isWrongSelection:
                                _answered &&
                                _selectedOption == option &&
                                option != widget.question.answer,
                            onTap: () => _handleAnswer(option),
                            enabled: !_answered,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_answered)
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          _isCorrect
                              ? '+$_xpReward XP earned!'
                              : 'Correct answer: ${widget.question.answer}',
                          style: TextStyle(
                            color: _isCorrect
                                ? const Color(0xFFF6D736)
                                : const Color(0xFFFF8FAB),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF6D736),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontFamily: 'MightySouly',
                            fontSize: 24,
                            letterSpacing: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _answered
                          ? () => Navigator.of(context).pop(_isCorrect)
                          : null,
                        child: Text(
                          _answered ? 'Back to Wheel' : 'Select an answer',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08,
                numberOfParticles: 25,
                maxBlastForce: 25,
                minBlastForce: 10,
                gravity: 0.2,
                colors: const [
                  Color(0xFFF6D736),
                  Color(0xFFFF9F1C),
                  Color(0xFFFF6392),
                  Color(0xFF00BBF9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAnswer(String option) async {
    if (_answered) return;

    final bool isCorrect = option == widget.question.answer;
    setState(() {
      _selectedOption = option;
      _answered = true;
      _isCorrect = isCorrect;
    });

    final notifier = ref.read(playerProgressProvider.notifier);
    await notifier.markQuestionUsed(widget.question.id);

    if (isCorrect) {
      _confettiController.play();
      await notifier.addXp(_xpReward);
      await notifier.addCoins(_coinReward);
    }
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.optionText,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrongSelection,
    required this.onTap,
    required this.enabled,
  });

  final String optionText;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrongSelection;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = const Color(0xFF1F1F1F);
    Color background = baseColor;
    Color border = Colors.white12;
    Color textColor = Colors.white;

    if (isSelected) {
      background = const Color(0xFF2C2C2C);
      border = const Color(0xFFF6D736);
    }
    if (isCorrect) {
      background = const Color(0xFF123524);
      border = const Color(0xFF4ADE80);
      textColor = const Color(0xFF9FE870);
    } else if (isWrongSelection) {
      background = const Color(0xFF3B0A0A);
      border = const Color(0xFFFF8FAB);
      textColor = const Color(0xFFFFB3C6);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || isSelected ? 1 : 0.7,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(
                      color: Color(0xFFF6D736),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
