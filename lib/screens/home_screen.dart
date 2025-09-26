import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_progress.dart';
import '../models/quiz_question.dart';
import '../providers/player_progress_provider.dart';
import '../providers/quiz_providers.dart';
import '../providers/storage_providers.dart';
import 'quiz_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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

  static const int _segmentCount = 12;

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
    final userName = ref
        .watch(sharedPreferencesProvider)
        .maybeWhen(
          data: (prefs) => prefs.getString('userName') ?? 'Explorer',
          orElse: () => 'Explorer',
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
        Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
        ),

        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3,
            sigmaY: 3, 
          ),
          child: Container(
            color: Colors.black.withOpacity(0), 
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: questionsAsync.when(
            data: (questions) => progressAsync.when(
              data: (progress) =>
                  _buildContent(context, userName, questions, progress),
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
    List<QuizQuestion> questions,
    PlayerProgress progress,
  ) {
    const Color neonYellow = Color(0xFFF6D736);

    final remaining = questions
        .where((q) => !progress.usedQuestionIds.contains(q.id))
        .toList(growable: false);
    final bool isEmpty = remaining.isEmpty;

    return Column(
      children: [

        _ProfileHeader(
          userName: userName,
          progress: progress,
          onStatsTap: () =>
              Navigator.of(context).pushNamed(StatsScreen.routeName),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 32),
              Text(
                'Spin the Wheel'.toUpperCase(),
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 36,
                  fontWeight: FontWeight.w700
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Answer quizzes to boost your XP and climb the ranks.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
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
                    child: isEmpty
                        ? _EmptyState(
                            onResetTap: () => _showResetDialog(context),
                          )
                        : _wheelSegments.isEmpty
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(),
                          )
                        : _WheelDisplay(
                            controller: _controller,
                            rotationAnimation: _rotationAnimation,
                            currentRotation: _currentRotation,
                            segments: _wheelSegments,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: neonYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        textStyle: const TextStyle(
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          letterSpacing: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                    ),
                    onPressed: _isSpinning || isEmpty
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
                const SizedBox(height: 44),
              ],
            ),
          ),
        ),
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                  question.category?.toUpperCase() ?? 'QUIZ',
                  style: const TextStyle(
                    color: Color(0xFFF6D736),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF6D736),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _openQuiz(question);
                },
                child: const Text(
                  'Answer Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            'You\'ve completed all quizzes! 🎉',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Reset your progress to spin again from the beginning?',
            style: TextStyle(color: Color(0xFFB5B5B5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF6D736),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.progress,
    required this.onStatsTap,
  });

  final String userName;
  final PlayerProgress progress;
  final VoidCallback onStatsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76 + MediaQuery.paddingOf(context).top + 10,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 10,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF6D736), width: 3),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6D736), Color(0xFFE2B400)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/avatar.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),

          // Username
          Expanded(
            child: Column (
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  progress.levelLabel,
                  style: const TextStyle(
                    color: Color(0xFF232522),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
            )
          ),

          // Coins pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF232522),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/coin.png', width: 24),
                const SizedBox(width: 20),
                Text(
                  '${progress.xp}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelDisplay extends StatelessWidget {
  const _WheelDisplay({
    required this.controller,
    required this.rotationAnimation,
    required this.currentRotation,
    required this.segments,
  });

  final AnimationController controller;
  final Animation<double>? rotationAnimation;
  final double currentRotation;
  final List<QuizQuestion> segments;

  static const _segmentCount = 12;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final angle = rotationAnimation?.value ?? currentRotation;
              return Transform.rotate(angle: angle, child: child);
            },
            child: CustomPaint(
              painter: _WheelPainter(
                labels: List<String>.generate(
                  _segmentCount,
                  (index) =>
                      _formatLabel(segments[index % segments.length].question),
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 8,
            child: Container(
              width: 58,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF6D736),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66F6D736),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.expand_more,
                color: Colors.black,
                size: 38,
              ),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF101010), Color(0xFF1C1C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Find your quiz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatLabel(String text) {
    const int limit = 36;
    final sanitized = text.replaceAll('\n', ' ').trim();
    if (sanitized.length <= limit) {
      return sanitized;
    }
    return '${sanitized.substring(0, limit - 1)}…';
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.labels});

  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / labels.length;
    final baseStart = -math.pi / 2 - segmentAngle / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final List<Color> segmentColors = [
      const Color(0xFF2F2F2F),
      const Color(0xFF232323),
    ];

    for (var i = 0; i < labels.length; i++) {
      final startAngle = baseStart + i * segmentAngle;
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            segmentColors[i % segmentColors.length],
            const Color(0xFF151515),
          ],
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, segmentAngle, true, fillPaint);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withAlpha(64)
        ..strokeWidth = 2.2;
      canvas.drawArc(
        rect.deflate(1.5),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.9);

      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.62;
      final textOffset = Offset(
        center.dx + textRadius * math.cos(textAngle) - textPainter.width / 2,
        center.dy + textRadius * math.sin(textAngle) - textPainter.height / 2,
      );

      canvas.save();
      canvas.translate(
        textOffset.dx + textPainter.width / 2,
        textOffset.dy + textPainter.height / 2,
      );
      canvas.rotate(-textAngle + math.pi / 2);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    final innerPaint = Paint()
      ..color = const Color(0xFF101010)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    if (oldDelegate.labels.length != labels.length) return true;
    for (var i = 0; i < labels.length; i++) {
      if (oldDelegate.labels[i] != labels[i]) return true;
    }
    return false;
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
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF202020), Color(0xFF121212)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white12),
          ),
          child: const Center(
            child: Text(
              'All quizzes completed! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF6D736),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: onResetTap,
          child: const Text(
            'Reset Progress',
            style: TextStyle(fontWeight: FontWeight.bold),
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
