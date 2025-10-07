import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';

import '../widgets/header.dart';
import '../widgets/wheel_display.dart';

import '../models/player_progress.dart';
import '../models/wheel_segment.dart';
import '../models/word_challenge.dart';

import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';
import '../providers/wheel_config_provider.dart';
import '../providers/word_providers.dart';

import 'word_quiz_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart';
import 'create_account_screen.dart';

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

  List<WheelSegmentConfig> _wheelSegments = const [];
  String? _segmentSignature;
  WheelSegmentConfig? _pendingSegment;
  int? _activeBet;
  bool _isSpinning = false;
  bool _isRedirecting = false;
  LevelUpEvent? _pendingLevelUp;
  LevelUpEvent? _deferredLevelUp;
  JackpotReward? _pendingJackpotReward;
  late final ConfettiController _confettiController;
  Timer? _levelUpTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleSpinCompleted();
        }
      });
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _levelUpTimer?.cancel();
    _confettiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheelConfig = ref.watch(wheelConfigProvider);
    final profileAsync = ref.watch(activeProfileProvider);
    final progressAsync = ref.watch(playerProgressProvider);
    ref.listen<LevelUpEvent?>(levelUpEventProvider, (previous, event) {
      if (event == null || !mounted) return;
      if (_pendingJackpotReward != null) {
        setState(() => _deferredLevelUp = event);
      } else {
        _showLevelUp(event);
      }
      ref.read(levelUpEventProvider.notifier).state = null;
    });
    ref.listen<JackpotReward?>(jackpotRewardProvider, (previous, reward) {
      if (reward == null || !mounted) return;
      setState(() {
        _pendingJackpotReward = reward;
        if (_pendingLevelUp != null) {
          _deferredLevelUp = _pendingLevelUp;
          _pendingLevelUp = null;
        }
      });
      _confettiController.play();
      _levelUpTimer?.cancel();
      ref.read(jackpotRewardProvider.notifier).state = null;
    });

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
          body: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                _redirectToAuth();
                return const Center(child: CircularProgressIndicator());
              }

              return progressAsync.when(
                data: (progress) {
                  _ensureWheelSegments(wheelConfig);
                  final remainingAsync = ref.watch(remainingWordChallengesProvider);
                  return remainingAsync.when(
                    data: (remaining) => _buildContent(
                      context,
                      profile,
                      progress,
                      wheelConfig,
                      remaining.isEmpty,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _ErrorState(message: error.toString()),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(message: error.toString()),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(message: error.toString()),
          ),
        ),
      ],
    );
  }

  void _ensureWheelSegments(WheelConfig config) {
    final signature = config.segments.map((segment) => segment.id.name).join('|');
    if (_segmentSignature == signature) {
      return;
    }
    _segmentSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _wheelSegments = _expandSegments(config.segments);
      });
    });
  }

  Widget _buildContent(
    BuildContext context,
    ProfileData profile,
    PlayerProgress progress,
    WheelConfig config,
    bool noWordsRemaining,
  ) {
    _ensureValidBet(progress, config);
    final int bet = _effectiveBet(progress, config);
    final bool hasSegments = _wheelSegments.isNotEmpty;
    final bool hasChips = progress.chips >= bet;
    final bool canSpin = !_isSpinning && hasSegments && hasChips && !noWordsRemaining;

    return Stack(
      children: [
        Column(
          children: [
            ProfileHeader(
              userName: profile.name,
              avatarIndex: profile.avatarIndex,
              progress: progress,
              onStatsTap: () => Navigator.of(context).pushNamed(StatsScreen.routeName),
            ),
            if (noWordsRemaining)
              Expanded(
                child: Center(
                  child: _EmptyState(onResetTap: () => _showResetDialog(context)),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 6),
                      const Text(
                        'Tap the wheel to discover your next word puzzle.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: hasSegments
                              ? _WheelDock(
                                  child: WheelDisplay(
                                    controller: _controller,
                                    rotationAnimation: _rotationAnimation,
                                    currentRotation: _currentRotation,
                                    labels: _wheelSegments
                                        .map((segment) =>
                                            segment.displayName.toUpperCase())
                                        .toList(growable: false),
                                    enabled: canSpin,
                                    onSpinPressed: () => _onWheelTapped(
                                      progress,
                                      config,
                                      hasSegments,
                                      hasChips,
                                      noWordsRemaining,
                                    ),
                                  ),
                                )
                              : const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!hasChips)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Not enough chips. Earn more to keep playing.',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_pendingJackpotReward != null)
          _JackpotCelebration(
            reward: _pendingJackpotReward!,
            controller: _confettiController,
            onDismiss: _dismissJackpotReward,
          )
        else if (_pendingLevelUp != null)
          _LevelUpCelebration(
            event: _pendingLevelUp!,
            controller: _confettiController,
            onDismiss: _dismissLevelUp,
          ),
      ],
    );
  }

  void _ensureValidBet(PlayerProgress progress, WheelConfig config) {
    if (progress.currentBet > 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(playerProgressProvider.notifier).setCurrentBet(config.spinCost);
    });
  }

  Future<void> _handleSpinPressed(
    PlayerProgress progress,
    WheelConfig config,
  ) async {
    if (_wheelSegments.isEmpty || _isSpinning) {
      return;
    }
    final bet = _effectiveBet(progress, config);
    if (progress.chips < bet) {
      _showSnack('Not enough chips to spin.');
      return;
    }

    await ref.read(playerProgressProvider.notifier).spendChips(bet);
    _activeBet = bet;

    final int segmentCount = _wheelSegments.length;
    final int targetIndex = _random.nextInt(segmentCount);
    final double segmentAngle = (2 * math.pi) / segmentCount;
    final double currentNorm = _normalizeAngle(_currentRotation);
    final double targetNorm = _normalizeAngle(-targetIndex * segmentAngle);

    double delta = targetNorm - currentNorm;
    if (delta <= 0) {
      delta += 2 * math.pi;
    }

    final int spins = 4 + _random.nextInt(3);
    final double finalRotation = _currentRotation + delta + spins * 2 * math.pi;

    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: finalRotation,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    setState(() {
      _isSpinning = true;
      _pendingSegment = _wheelSegments[targetIndex];
    });

    _controller
      ..reset()
      ..forward();
  }

  void _onWheelTapped(
    PlayerProgress progress,
    WheelConfig config,
    bool hasSegments,
    bool hasChips,
    bool noWordsRemaining,
  ) {
    if (_isSpinning || !hasSegments) {
      return;
    }
    if (noWordsRemaining) {
      _showSnack('No words available for this segment right now. Reset your progress to continue.');
      return;
    }
    if (!hasChips) {
      _showSnack('Not enough chips to spin.');
      return;
    }
    _handleSpinPressed(progress, config);
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

    final segment = _pendingSegment;
    _pendingSegment = null;
    if (segment != null) {
      _openSegmentResult(segment);
    }
  }

  Future<void> _openSegmentResult(WheelSegmentConfig segment) async {
    final bet = _activeBet ?? ref.read(playerProgressProvider).value?.currentBet ?? 0;
    _activeBet = null;

    final allWords = await ref.read(wordChallengesProvider.future);
    final progressValue = ref.read(playerProgressProvider).value;
    final used = progressValue?.completedWordIds ?? <String>{};

    final WordChallenge? challenge =
        await _prepareChallengeForSegment(segment, allWords, used);
    if (!mounted) return;

    if (challenge == null) {
      if (bet > 0) {
        await ref.read(playerProgressProvider.notifier).addChips(bet);
      }
      _showSnack('No words available for this segment right now.');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WordQuizScreen(
          challenge: challenge,
          segmentId: segment.id,
          bet: bet,
          rewardMultiplier: segment.rewardMultiplier,
          penaltyMultiplier: segment.penaltyMultiplier,
          modifiers: segment.modifiers,
        ),
      ),
    );

    if (result == true) {
      HapticFeedback.mediumImpact();
      if (segment.modifiers.contains(WheelModifierType.jackpotMeter)) {
        await ref.read(playerProgressProvider.notifier).advanceJackpot(20);
      } else {
        await ref.read(playerProgressProvider.notifier).advanceJackpot(5);
      }
    }

    ref.invalidate(playerProgressProvider);
    ref.invalidate(remainingWordChallengesProvider);
  }

  Future<WordChallenge?> _prepareChallengeForSegment(
    WheelSegmentConfig segment,
    List<WordChallenge> allWords,
    Set<String> used,
  ) async {
    final pool = _buildWordPool(allWords, used);
    if (pool.isEmpty) return null;

    WordChallenge? base = _pickWordForSegment(segment, pool);
    if (base == null) return null;

    WordChallenge? alternate;

    if (segment.modifiers.contains(WheelModifierType.doubleDown)) {
      alternate = _pickAlternateWord(pool, excludeIds: {base.id});
      if (alternate != null) {
        base = base.copyWith(
          comboAnswers: <String>[
            ...?base.comboAnswers,
            alternate.answer,
          ],
        );
      }
    }

    if (segment.modifiers.contains(WheelModifierType.wildcardChoice)) {
      alternate ??= _pickAlternateWord(pool, excludeIds: {base.id});
      final alternateWord = alternate;
      if (alternateWord == null) {
        return base;
      }
      final resolvedAlternate = segment.modifiers.contains(WheelModifierType.doubleDown)
          ? alternateWord.copyWith(
              comboAnswers: <String>[
                ...?alternateWord.comboAnswers,
                base.answer,
              ],
            )
          : alternateWord;
      if (!mounted) {
        return base;
      }
      final choice = await _showWildcardChoice(base, resolvedAlternate);
      if (choice == null) {
        return null;
      }
      base = choice;
    }

    return base;
  }

  List<WordChallenge> _buildWordPool(
    List<WordChallenge> allWords,
    Set<String> used,
  ) {
    final unused =
        allWords.where((word) => !used.contains(word.id)).toList(growable: false);
    if (unused.isNotEmpty) return unused;
    return List<WordChallenge>.from(allWords);
  }

  List<WheelSegmentConfig> _expandSegments(List<WheelSegmentConfig> segments) {
    final expanded = <WheelSegmentConfig>[];
    for (final segment in segments) {
      final count = math.max(1, math.min(segment.weight ?? 1, 4));
      for (var i = 0; i < count; i++) {
        expanded.add(segment);
      }
    }
    return expanded.isEmpty ? segments : expanded;
  }

  WordChallenge? _pickWordForSegment(
    WheelSegmentConfig segment,
    List<WordChallenge> pool,
  ) {
    if (pool.isEmpty) return null;
    final difficulty = segment.baseDifficulty.toLowerCase();
    if (segment.modifiers.contains(WheelModifierType.randomizer)) {
      return pool[_random.nextInt(pool.length)];
    }
    final matches = pool
        .where((word) => (word.difficulty ?? 'easy').toLowerCase() == difficulty)
        .toList(growable: false);
    final candidates = matches.isNotEmpty ? matches : pool;
    return candidates[_random.nextInt(candidates.length)];
  }

  WordChallenge? _pickAlternateWord(
    List<WordChallenge> pool, {
    Set<String>? excludeIds,
  }) {
    final candidates = pool
        .where((word) => !(excludeIds?.contains(word.id) ?? false))
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  Future<WordChallenge?> _showWildcardChoice(
    WordChallenge primary,
    WordChallenge alternate,
  ) {
    return showDialog<WordChallenge>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            'Choose your word category',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WildcardOption(
                challenge: primary,
                onTap: () => Navigator.of(context).pop(primary),
              ),
              const SizedBox(height: 12),
              _WildcardOption(
                challenge: alternate,
                onTap: () => Navigator.of(context).pop(alternate),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _redirectToAuth() {
    if (_isRedirecting) return;
    _isRedirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final profiles = readAllProfiles(prefs);
      if (!mounted) return;
      final route = profiles.isEmpty
          ? CreateAccountScreen.routeName
          : LoginScreen.routeName;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(route, (route) => false);
    });
  }

  double _normalizeAngle(double angle) {
    final double twoPi = 2 * math.pi;
    angle = angle % twoPi;
    if (angle < 0) angle += twoPi;
    return angle;
  }

  int _effectiveBet(PlayerProgress progress, WheelConfig config) {
    final bet = progress.currentBet;
    if (bet <= 0) {
      return config.spinCost;
    }
    return bet;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLevelUp(LevelUpEvent event) {
    if (!mounted) return;
    setState(() => _pendingLevelUp = event);
    _confettiController.play();
    _levelUpTimer?.cancel();
    _levelUpTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _dismissLevelUp();
    });
  }

  void _dismissLevelUp() {
    _levelUpTimer?.cancel();
    if (!mounted) return;
    setState(() => _pendingLevelUp = null);
  }

  void _dismissJackpotReward() {
    if (!mounted) return;
    LevelUpEvent? deferred;
    setState(() {
      _pendingJackpotReward = null;
      deferred = _deferredLevelUp;
      _deferredLevelUp = null;
    });
    if (deferred != null) {
      _showLevelUp(deferred!);
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
            'You\'ve completed all words!',
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

class _WheelDock extends StatelessWidget {
  const _WheelDock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelSize = screenWidth;
    final visibleHeight = wheelSize * 0.85;

    return SizedBox(
      width: double.infinity,
      height: visibleHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 140,
            child: SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: child,
            ),
          ),
        ],
      ),
    );
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
        const Icon(Icons.celebration_rounded, color: Color(0xFFFFAF28), size: 48),
        const SizedBox(height: 12),
        const Text(
          'All words completed!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 24),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onResetTap,
          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          label: const Text('Reset Progress'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFAF28),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontFamily: 'Cookies', fontSize: 20),
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

class _LevelUpCelebration extends StatelessWidget {
  const _LevelUpCelebration({
    required this.event,
    required this.controller,
    required this.onDismiss,
  });

  final LevelUpEvent event;
  final ConfettiController? controller;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ModalBarrier(
            color: Colors.black.withValues(alpha: 0.75),
            dismissible: true,
            onDismiss: onDismiss,
          ),
          if (controller != null)
            ConfettiWidget(
              confettiController: controller!,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              maxBlastForce: 18,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              colors: const [
                Color(0xFFFFAF28),
                Color(0xFF00F5A0),
                Color(0xFF4C6FFF),
                Colors.white,
              ],
            ),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFAF28), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFFFAF28), size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Level Up!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You reached ${event.label}.',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JackpotCelebration extends StatelessWidget {
  const _JackpotCelebration({
    required this.reward,
    required this.controller,
    required this.onDismiss,
  });

  final JackpotReward reward;
  final ConfettiController? controller;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final boostEntries = reward.boosts.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ModalBarrier(
            color: Colors.black.withValues(alpha: 0.75),
            dismissible: true,
            onDismiss: onDismiss,
          ),
          if (controller != null)
            ConfettiWidget(
              confettiController: controller!,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              maxBlastForce: 20,
              minBlastForce: 10,
              emissionFrequency: 0.04,
              colors: const [
                Color(0xFFFFAF28),
                Color(0xFF00F5A0),
                Color(0xFF4C6FFF),
                Colors.white,
              ],
            ),
          Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFAF28), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.casino, color: Color(0xFFFFAF28), size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'Jackpot Unlocked!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your spins filled the jackpot meter. Collect your bonus loot!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  _JackpotRewardTile(
                    icon: Icons.local_fire_department,
                    label: 'Bonus Chips',
                    value: '+${reward.chips}',
                  ),
                  if (boostEntries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: boostEntries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _JackpotRewardTile(
                                icon: _boostIcon(entry.key),
                                label: _boostLabel(entry.key),
                                value: '×${entry.value}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFAF28),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Collect Rewards'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _boostIcon(BoostType type) {
    switch (type) {
      case BoostType.reSpin:
        return Icons.shuffle_rounded;
      case BoostType.revealLetter:
        return Icons.lightbulb_outline;
      case BoostType.swapTiles:
        return Icons.swap_horiz_rounded;
      case BoostType.timeFreeze:
        return Icons.ac_unit_rounded;
      case BoostType.streakShield:
        return Icons.shield_outlined;
    }
  }

  static String _boostLabel(BoostType type) {
    switch (type) {
      case BoostType.reSpin:
        return 'Tile Shuffle Boost';
      case BoostType.revealLetter:
        return 'Reveal Letter Boost';
      case BoostType.swapTiles:
        return 'Swap Tiles Boost';
      case BoostType.timeFreeze:
        return 'Time Freeze Boost';
      case BoostType.streakShield:
        return 'Streak Shield Boost';
    }
  }
}

class _JackpotRewardTile extends StatelessWidget {
  const _JackpotRewardTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFAF28), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WildcardOption extends StatelessWidget {
  const _WildcardOption({required this.challenge, required this.onTap});

  final WordChallenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe58923)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.category,
              style: const TextStyle(
                color: Color(0xFFFFAF28),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Difficulty: ${(challenge.difficulty ?? 'Easy').toUpperCase()}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (challenge.hint != null && challenge.hint!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                challenge.hint!,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
