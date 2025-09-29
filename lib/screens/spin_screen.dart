import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';

import '../widgets/header.dart';
import '../widgets/wheel_display.dart';

import '../models/player_progress.dart';
import '../models/quiz_question.dart';

import '../providers/player_progress_provider.dart';
import '../providers/quiz_providers.dart';
import '../providers/storage_providers.dart';

import 'quiz_screen.dart';
import 'stats_screen.dart';

class SpinScreen extends ConsumerStatefulWidget {
  const SpinScreen({super.key});

  static const routeName = '/spin';

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _rotationAnimation;
  double _currentRotation = 0;
  final math.Random _random = math.Random();

  List<QuizQuestion> _wheelSegments = const [];
  String? _questionsSignature;
  String? _usedSignature;
  bool _isSpinning = false;
  QuizQuestion? _pendingQuestion;

  static const int _segmentCount = 8;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 5200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _handleSpinCompleted();
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    final userName = prefsAsync.maybeWhen(
      data: (prefs) => prefs.getString('userName') ?? 'Explorer',
      orElse: () => 'Explorer',
    );

    final avatarIndex = prefsAsync.maybeWhen(
      data: (prefs) => prefs.getInt('profileAvatar') ?? 0,
      orElse: () => 0,
    );

    final questionsAsync = ref.watch(quizQuestionsProvider);
    final progressAsync = ref.watch(playerProgressProvider);

    if (questionsAsync.hasValue && progressAsync.hasValue) {
      _scheduleWheelSync(
        questionsAsync.value ?? const [],
        progressAsync.value!,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withAlpha(26)),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: questionsAsync.when(
            data: (questions) => progressAsync.when(
              data: (progress) => _buildContent(
                context,
                userName,
                avatarIndex,
                questions,
                progress,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(message: error.toString()),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(message: error.toString()),
          ),
        ),
      ],
    );
  }

  void _scheduleWheelSync(
    List<QuizQuestion> allQuestions,
    PlayerProgress progress,
  ) {
    final questionSignature = _buildSignature(allQuestions.map((q) => q.id));
    final usedSignature = _buildSignature(progress.usedQuestionIds);
    final needsSync =
        _wheelSegments.isEmpty ||
        _questionsSignature != questionSignature ||
        _usedSignature != usedSignature;

    if (!needsSync || _isSpinning) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _questionsSignature = questionSignature;
      _usedSignature = usedSignature;
      _wheelSegments = _generateWheelSegments(
        allQuestions,
        progress.usedQuestionIds,
      );
      setState(() {});
    });
  }

  Widget _buildContent(
    BuildContext context,
    String userName,
    int avatarIndex,
    List<QuizQuestion> questions,
    PlayerProgress progress,
  ) {
    const Color neonYellow = Color(0xFFffaf28);

    final remaining = questions
        .where((q) => !progress.usedQuestionIds.contains(q.id))
        .toList(growable: false);
    final bool isEmpty = remaining.isEmpty;

    return Column(
      children: [
        ProfileHeader(
          userName: userName,
          avatarIndex: avatarIndex,
          progress: progress,
          onStatsTap: () =>
              Navigator.of(context).pushNamed(StatsScreen.routeName),
        ),

        if (isEmpty)
          Expanded(
            child: Center(
              child: _EmptyState(onResetTap: () => _showResetDialog(context)),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32),
                Stack(
                  children: [
                    Text(
                      'Spin the Wheel',
                      style: TextStyle(
                        fontSize: 44,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 4
                          ..color = const Color(0xFFE2B400),
                      ),
                    ),
                    Text(
                      'Spin the Wheel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        color: Color(0xFF000000),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFF6D736),
                            blurRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Answer quizzes to boost your XP and \n climb the ranks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: _wheelSegments.isEmpty
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(),
                            )
                          : WheelDisplay(
                              controller: _controller,
                              rotationAnimation: _rotationAnimation,
                              currentRotation: _currentRotation,
                              segments: _wheelSegments,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _isSpinning ? const Color(0x669E9E9E) : const Color(0xFFe58923),
                            width: 3,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(34),
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: neonYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: const TextStyle(
                            fontFamily: 'MightySouly',
                            fontSize: 24,
                            letterSpacing: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        onPressed: _isSpinning
                            ? null
                            : () => _handleSpinPressed(),
                        child: _isSpinning
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Spin Now'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _buildSignature(Iterable<String> values) {
    final sorted = values.toList()..sort();
    return sorted.join('|');
  }

  List<QuizQuestion> _generateWheelSegments(
    List<QuizQuestion> questions,
    Set<String> used,
  ) {
    final available = questions.where((q) => !used.contains(q.id)).toList();
    if (available.isEmpty) {
      return const [];
    }

    available.shuffle(_random);
    if (available.length >= _segmentCount) {
      return available.take(_segmentCount).toList(growable: false);
    }

    final segments = List<QuizQuestion>.from(available);
    while (segments.length < _segmentCount) {
      segments.add(available[_random.nextInt(available.length)]);
    }
    return segments;
  }

  void _handleSpinPressed() {
    if (_wheelSegments.isEmpty || _isSpinning) {
      return;
    }

    final int targetIndex = _random.nextInt(_wheelSegments.length);
    final double segmentAngle = (2 * math.pi) / _segmentCount;
    final double currentNorm = _normalizeAngle(_currentRotation);
    final double targetNorm = _normalizeAngle(-targetIndex * segmentAngle);

    double delta = targetNorm - currentNorm;
    if (delta <= 0) {
      delta += 2 * math.pi;
    }

    final int spins = 4 + _random.nextInt(3); // 4-6 extra spins
    final double finalRotation = _currentRotation + delta + spins * 2 * math.pi;

    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: finalRotation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    setState(() {
      _isSpinning = true;
      _pendingQuestion = _wheelSegments[targetIndex];
    });

    _controller
      ..reset()
      ..forward();
  }

  void _handleSpinCompleted() {
    if (!mounted) return;
    setState(() {
      if (_rotationAnimation != null) {
        _currentRotation = _normalizeAngle(_rotationAnimation!.value);
      }
      _rotationAnimation = null;
      _isSpinning = false;
    });

    if (_pendingQuestion != null) {
      _showQuestionPreview(_pendingQuestion!);
    }
    _pendingQuestion = null;
  }

  double _normalizeAngle(double angle) {
    final double twoPi = 2 * math.pi;
    angle = angle % twoPi;
    if (angle < 0) angle += twoPi;
    return angle;
  }

  Future<void> _showQuestionPreview(QuizQuestion question) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232323),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    question.category ?? 'QUIZ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFF6D736)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                question.question,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    border: const Border(
                      bottom: BorderSide(
                        color: Color(0xFFe58923),
                        width: 3,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFffaf28),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontFamily: 'MightySouly',
                        fontSize: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openQuiz(question);
                    },
                    child: const Text('Answer Now'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openQuiz(QuizQuestion question) async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(question: question)),
    );

    if (result == true) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'You\'ve completed all quizzes!',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Reset your progress to spin again from the beginning?',
            style: TextStyle(color: Color(0xFFB5B5B5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now', style: TextStyle(fontSize: 16)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF6D736),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );

    if (shouldReset == true && mounted) {
      await ref.read(playerProgressProvider.notifier).resetProgress();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onResetTap});

  final VoidCallback onResetTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'All quizzes completed!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 24),
        ),

        const SizedBox(height: 24),
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFe58923),
                  width: 2,
                ),
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onResetTap,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFAF28), size: 20),
              label: const Text('Reset Progress', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 16),
            Text(
              'Something went wrong:\n$message',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
