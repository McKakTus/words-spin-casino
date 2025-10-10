import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/boost_catalog.dart';
import '../helpers/image_paths.dart';

import '../widgets/stroke_text.dart';
import '../widgets/stroke_icon.dart';
import '../widgets/primary_button.dart';

import '../models/player_progress.dart';
import '../models/wheel_segment.dart';
import '../models/word_challenge.dart';

import '../providers/player_progress_provider.dart';

import 'boost_shop_screen.dart';
import 'stats_screen.dart';

enum WordQuizMode { standard }

class WordQuizScreen extends ConsumerStatefulWidget {
  const WordQuizScreen({
    super.key,
    required this.challenge,
    required this.modifiers,
    this.mode = WordQuizMode.standard,
    this.segmentId,
    this.bet,
    this.rewardMultiplier = 1.0,
    this.penaltyMultiplier = 1.0,
  });

  final WordChallenge challenge;
  final List<WheelModifierType> modifiers;
  final WordQuizMode mode;
  final WheelSegmentId? segmentId;
  final int? bet;
  final double rewardMultiplier;
  final double penaltyMultiplier;

  @override
  ConsumerState<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends ConsumerState<WordQuizScreen>
    with SingleTickerProviderStateMixin {
  final Map<int, WordTile> _filledSlots = <int, WordTile>{};
  final Set<String> _usedTileIds = <String>{};
  final Set<String> _disabledTileIds = <String>{};
  final math.Random _random = math.Random();

  late final Set<WheelModifierType> _modifiers;
  late final List<_StageData> _stages;
  late final int _baseXpReward;
  late final int _baseChipReward;
  late final String _backgroundAsset;

  late List<WordLetterSlot> _currentSlots;
  late List<WordTile> _tiles;
  String? _currentHint;

  Timer? _errorTimer;
  Timer? _countdownTimer;
  Timer? _burningTimer;
  Timer? _preRoundTimer;
  Timer? _countdownHideTimer;
  Timer? _timeFreezeTimer;

  int _stageIndex = 0;
  int _timeLimitSeconds = 0;
  int _timeRemaining = 0;
  bool _hasTimedOut = false;
  bool _isSubmitting = false;
  bool _completed = false;
  bool _failureProcessed = false;
  bool _timeFreezeActive = false;
  bool _resumeBurningAfterFreeze = false;
  bool _resumeCountdownAfterPause = false;
  bool _resumeBurningAfterPause = false;
  bool _resumePreRoundAfterPause = false;
  bool _isPaused = false;
  bool _showPauseOverlay = false;
  bool _showBoostsOverlay = false;
  bool _pausedForBoostOverlay = false;
  bool _showCountdownOverlay = false;
  int? _countdownValue;
  bool _swapTilesMode = false;
  String? _swapTileSelection;
  bool _streakShieldActive = false;
  bool _boostActivationInProgress = false;
  BoostType? _activatingBoost;
  int? _highlightedSlotIndex;
  _RewardSummary? _pendingReward;
  String? _errorTileId;
  Duration? _timeFreezeRemaining;
  DateTime? _timeFreezeExpiresAt;

  int get _totalStages => _stages.length;
  _StageData get _stage => _stages[_stageIndex];
  bool get _isPreRoundActive => _showCountdownOverlay;

  @override
  void initState() {
    super.initState();
    _modifiers = widget.modifiers.toSet();
    final backgrounds = Images.backgrounds;
    if (backgrounds.isNotEmpty) {
      _backgroundAsset = backgrounds[_random.nextInt(backgrounds.length)];
    } else {
      _backgroundAsset = Images.background;
    }
    _initializeStages();
    _baseXpReward = _computeBaseXp(_stage.difficulty, _stage.answer.length);
    _baseChipReward = _computeBaseChips(_stage.difficulty, _stage.answer.length);
    _loadStage(0);
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _countdownTimer?.cancel();
    _burningTimer?.cancel();
    _preRoundTimer?.cancel();
    _countdownHideTimer?.cancel();
    _timeFreezeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProgressAsync = ref.watch(playerProgressProvider);
    final playerProgress = playerProgressAsync.value;
    final statusChips = _statusChips();
    final bool hasHint = _currentHint != null && _currentHint!.trim().isNotEmpty;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool canOpenBoostOverlay = playerProgress != null &&
        !_showBoostsOverlay &&
        !_showPauseOverlay &&
        !_isPreRoundActive &&
        _pendingReward == null &&
        !_boostActivationInProgress &&
        !_isSubmitting &&
        !_completed &&
        !_hasTimedOut;

    if (playerProgress == null && _showBoostsOverlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _closeBoostsOverlay();
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_backgroundAsset, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000), 
                  Color(0x66000000), 
                  Color(0x00000000),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: PrimaryButton(
                          label: const StrokeIcon(
                            icon: Icons.pause_rounded,
                            size: 22,
                          ),
                          onPressed: _handlePausePressed,
                          borderRadius: 12,
                          uppercase: false,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: StrokeText(
                            text: widget.challenge.category.toUpperCase(),
                            fontSize: 32,
                            height: 1,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: PrimaryButton(
                          label: StrokeIcon(
                            icon: Icons.bolt_rounded,
                            size: 22,
                          ),
                          borderRadius: 12,
                          onPressed: canOpenBoostOverlay ? _openBoostsOverlay : null,
                          enabled: canOpenBoostOverlay,
                          uppercase: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildOverviewSection(
                    colorScheme: colorScheme,
                    statusChips: statusChips,
                    hasHint: hasHint,
                  ),
                  const SizedBox(height: 28),
                  _buildSlotsSection(colorScheme),
                  const SizedBox(height: 18),
                  _buildGuideText(colorScheme),
                  const SizedBox(height: 18),
                  _buildTilePanel(colorScheme),
                  const SizedBox(height: 20),
                  _buildActions(context, colorScheme),
                ],
              ),
            ),
          ),
        ),
        if (_showCountdownOverlay)
          _CountdownOverlay(
            value: _countdownValue,
          ),
        if (_pendingReward != null)
          _RewardCelebration(
            summary: _pendingReward!,
            onDismiss: _dismissReward,
            chipRewardImage: Images.coin,
            xpRewardImage: Images.xp,
          ),
        if (_showBoostsOverlay && playerProgress != null)
          _BoostsOverlay(
            inventory: playerProgress.boostInventory,
            onBoostSelected: _activateBoostFromOverlay,
            onDismiss: () => _closeBoostsOverlay(),
            canActivate: (type) => !_boostActivationInProgress && _canActivateBoost(type),
            infoBuilder: BoostCatalog.info,
          ),
        if (_showPauseOverlay)
          _PauseOverlay(
            onResume: _resumeGame,
            onShop: () => _navigateFromPause(BoostShopScreen.routeName),
            onStats: () => _navigateFromPause(StatsScreen.routeName),
            onEndQuiz: _endQuizEarly,
          ),
      ],
    );
  }

  void _initializeStages() {
    _stages = <_StageData>[
      _StageData(
        answer: widget.challenge.answer,
        hint: widget.challenge.hint,
        difficulty: widget.challenge.difficulty ?? 'easy',
        extraLetters: widget.challenge.extraLetters,
      ),
    ];

    final combos = widget.challenge.comboAnswers;
    if (combos != null && combos.isNotEmpty) {
      for (final combo in combos) {
        _stages.add(
          _StageData(
            answer: combo,
            hint: null,
            difficulty: widget.challenge.difficulty ?? 'medium',
            extraLetters: const <String>[],
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_isPreRoundActive) {
      return;
    }
    if (_hasTimedOut) {
      await _handleFailure('Time\'s up! Try again for rewards.');
      return;
    }
    if (!_isReady() || _isSubmitting) {
      _showSnack('Complete the word before confirming.');
      return;
    }

    setState(() => _isSubmitting = true);
    _countdownTimer?.cancel();
    _burningTimer?.cancel();

    final bool hasMoreStages = _stageIndex < _totalStages - 1;
    if (hasMoreStages) {
      if (_modifiers.contains(WheelModifierType.optionalRisk)) {
        final continuePlay = await _showDoubleDownPrompt();
        if (continuePlay != true) {
          await _finalizeSuccess();
          return;
        }
      }
      _loadStage(_stageIndex + 1);
      setState(() => _isSubmitting = false);
      return;
    }

    await _finalizeSuccess();
    return;
  }

  List<Widget> _statusChips() {
    final chips = <Widget>[];
    if (_timeFreezeActive) {
      chips.add(const _StatusChip(
        icon: Icons.ac_unit_rounded,
        label: 'Time Frozen',
      ));
    }
    if (_swapTilesMode) {
      chips.add(const _StatusChip(
        icon: Icons.swap_horiz_rounded,
        label: 'Select tiles to swap',
        highlight: true,
      ));
    }
    if (_streakShieldActive) {
      chips.add(const _StatusChip(
        icon: Icons.shield_rounded,
        label: 'Streak Shield ready',
      ));
    }
    return chips;
  }

  void _handlePausePressed() {
    if (_pendingReward != null) {
      return;
    }
    if (_showBoostsOverlay) {
      _closeBoostsOverlay(resume: false);
    }
    if (_showPauseOverlay) {
      _resumeGame();
    } else {
      _pauseGame();
      setState(() => _showPauseOverlay = true);
    }
  }

  void _pauseGame() {
    if (_isPaused) {
      return;
    }
    _resumeCountdownAfterPause = _countdownTimer != null;
    _resumeBurningAfterPause = _burningTimer != null && !_timeFreezeActive;
    _resumePreRoundAfterPause = _showCountdownOverlay;

    _countdownTimer?.cancel();
    _countdownTimer = null;
    _burningTimer?.cancel();
    _burningTimer = null;

    if (_resumePreRoundAfterPause) {
      _preRoundTimer?.cancel();
      _preRoundTimer = null;
      _countdownHideTimer?.cancel();
      _countdownHideTimer = null;
    }

    if (_timeFreezeActive) {
      _timeFreezeRemaining = _timeFreezeExpiresAt?.difference(DateTime.now());
      if (_timeFreezeRemaining != null && _timeFreezeRemaining!.isNegative) {
        _timeFreezeRemaining = Duration.zero;
      }
      _timeFreezeTimer?.cancel();
      _timeFreezeTimer = null;
      _timeFreezeExpiresAt = null;
    }

    setState(() {
      _isPaused = true;
    });
  }

  void _resumeGame() {
    if (!_isPaused && !_showPauseOverlay) {
      return;
    }
    final bool shouldRestartCountdown =
        _resumeCountdownAfterPause && !_isPreRoundActive && !_timeFreezeActive;
    final bool shouldRestartBurning =
        (_resumeBurningAfterPause ||
                (_resumeBurningAfterFreeze && !_timeFreezeActive)) &&
            _modifiers.contains(WheelModifierType.burningTiles);

    setState(() {
      _showPauseOverlay = false;
      _isPaused = false;
    });

    if (_timeFreezeActive) {
      final Duration? remaining = _timeFreezeRemaining;
      if (remaining != null && remaining > Duration.zero) {
        _timeFreezeExpiresAt = DateTime.now().add(remaining);
        _timeFreezeTimer = Timer(remaining, _onTimeFreezeExpired);
      } else if (remaining != null) {
        _onTimeFreezeExpired();
      }
      _timeFreezeRemaining = null;
    }

    if (_resumePreRoundAfterPause) {
      _resumePreRoundAfterPause = false;
      if (_countdownValue == null) {
        _onPreRoundCountdownFinished();
      } else {
        _beginPreRoundCountdown(startValue: _countdownValue!);
      }
    } else {
      if (shouldRestartCountdown && _countdownTimer == null) {
        _startCountdown();
      }

      if (shouldRestartBurning && _burningTimer == null) {
        _startBurningTimer();
      }
    }

    _resumeCountdownAfterPause = false;
    _resumeBurningAfterPause = false;
  }

  void _openBoostsOverlay() {
    if (_isPreRoundActive ||
        _showBoostsOverlay ||
        _showPauseOverlay ||
        _pendingReward != null) {
      return;
    }
    final bool wasPaused = _isPaused;
    if (!wasPaused) {
      _pauseGame();
    }
    setState(() => _showBoostsOverlay = true);
    _pausedForBoostOverlay = !wasPaused;
  }

  void _closeBoostsOverlay({bool resume = true}) {
    if (!_showBoostsOverlay) {
      _pausedForBoostOverlay = false;
      return;
    }
    setState(() => _showBoostsOverlay = false);
    final bool shouldResume = resume && _pausedForBoostOverlay;
    _pausedForBoostOverlay = false;
    if (shouldResume) {
      _resumeGame();
    }
  }

  void _activateBoostFromOverlay(BoostType type) {
    _closeBoostsOverlay();
    _handleBoostPressed(type);
  }

  Future<void> _navigateFromPause(String routeName) async {
    if (!_isPaused) {
      _pauseGame();
    }
    setState(() => _showPauseOverlay = false);
    await Navigator.of(context).pushNamed(routeName);
    if (!mounted) return;
    _resumeGame();
  }

  Future<void> _endQuizEarly() async {
    if (!_mountedAndActive()) return;
    _timeFreezeTimer?.cancel();
    _timeFreezeTimer = null;
    setState(() {
      _showPauseOverlay = false;
      _isPaused = false;
      _timeFreezeActive = false;
      _timeFreezeExpiresAt = null;
      _timeFreezeRemaining = null;
    });
    if (_streakShieldActive) {
      setState(() => _streakShieldActive = false);
    }
    await _handleFailure('Quiz ended early. Wager forfeited.');
  }

  bool _mountedAndActive() => mounted && !_completed;

  Widget _buildOverviewSection({
    required ColorScheme colorScheme,
    required List<Widget> statusChips,
    required bool hasHint,
  }) {
    final bool showStatus = !_isPreRoundActive && statusChips.isNotEmpty;
    final bool showStage = !_isPreRoundActive && _totalStages > 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.22),
            colorScheme.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStatus) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: statusChips,
            ),
          ],
          if (hasHint) ...[
            const SizedBox(height: 16),
            _buildHintBanner(colorScheme),
          ],
          const SizedBox(height: 16),
          if (showStage) ...[
            _buildStageIndicator(colorScheme),
            const SizedBox(height: 8),
          ],
          _buildTimerBadge(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSlotsSection(ColorScheme colorScheme) {
    final Color background = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.08),
      Colors.black.withValues(alpha: 0.76),
    );
    final Color border = colorScheme.primary.withValues(alpha: 0.18);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Center(child: _buildSlotsRow(colorScheme)),
    );
  }

  Widget _buildGuideText(ColorScheme colorScheme) {
    final String message;
    if (_hasTimedOut) {
      message = 'Time expired — try again to secure your reward.';
    } else if (_isPreRoundActive) {
      message = 'Get ready! Letters unlock when the countdown ends.';
    } else {
      message = 'Tap letters to fill each slot. Tap any slot to clear it.';
    }

    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.72),
        fontSize: 14,
        height: 1.35,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildTilePanel(ColorScheme colorScheme) {
    final Color background = Color.alphaBlend(
      colorScheme.secondary.withValues(alpha: 0.08),
      Colors.black.withValues(alpha: 0.8),
    );
    final Color border = colorScheme.secondary.withValues(alpha: 0.18);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 22,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
      child: Center(child: _buildTilesGrid(colorScheme)),
    );
  }

  Widget _buildStageIndicator(ColorScheme colorScheme) {
    if (_totalStages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.45)),
      ),
      child: Text(
        'Stage ${_stageIndex + 1} of $_totalStages',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildTimerBadge(ColorScheme colorScheme) {
    if (_timeLimitSeconds <= 0) return const SizedBox.shrink();
    final double progress = _timeLimitSeconds == 0
        ? 0.0
        : (_timeRemaining.clamp(0, _timeLimitSeconds)) / _timeLimitSeconds;
    final Color progressStart =
        _hasTimedOut ? const Color(0xFFFF4D6D) : colorScheme.primary;
    final Color progressEnd =
        _hasTimedOut ? const Color(0xFFFF8E9D) : colorScheme.secondary;
    final Color trackColor = Colors.white.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: double.infinity,
          height: 14,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double targetWidth =
                  (_hasTimedOut ? 0 : progress) * maxWidth;
              final BorderRadius radius = BorderRadius.circular(18);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: radius,
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: targetWidth.clamp(0.0, maxWidth),
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          colors: [progressStart, progressEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: progressEnd.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_timeRemaining),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_hasTimedOut)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Time expired',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildHintBanner(ColorScheme colorScheme) {
    final String? hint = _currentHint;
    if (hint == null || hint.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final Color background = Color.alphaBlend(
      colorScheme.primary.withOpacity(0.16),
      Colors.black.withOpacity(0.65),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.3,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsRow(ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: _currentSlots
          .map(
            (slot) => _SlotChip(
              colorScheme: colorScheme,
              isFilled: _filledSlots.containsKey(slot.index),
              letter: _filledSlots[slot.index]?.character,
              isHighlighted: _highlightedSlotIndex == slot.index,
              onTap: _filledSlots.containsKey(slot.index) &&
                      !_isSubmitting &&
                      !_completed &&
                      !_hasTimedOut &&
                      !_swapTilesMode
                  ? () => _clearSlot(slot.index)
                  : null,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTilesGrid(ColorScheme colorScheme) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: _tiles
          .map(
            (tile) => _LetterTile(
              tile: tile,
              isUsed: _usedTileIds.contains(tile.id),
              isDisabled: _isSubmitting ||
                  _completed ||
                  _hasTimedOut ||
                  _disabledTileIds.contains(tile.id),
              isError: _errorTileId == tile.id,
              isSwapMode: _swapTilesMode,
              isSwapSelectable: _swapTilesMode &&
                  !_usedTileIds.contains(tile.id) &&
                  !_disabledTileIds.contains(tile.id) &&
                  !_isSubmitting &&
                  !_completed &&
                  !_hasTimedOut,
              isSwapSelected: _swapTileSelection == tile.id,
              colorScheme: colorScheme,
              onTap: !_swapTilesMode
                  ? () => _handleTileTap(tile)
                  : (_swapTilesMode &&
                          !_usedTileIds.contains(tile.id) &&
                          !_disabledTileIds.contains(tile.id) &&
                          !_isSubmitting &&
                          !_completed &&
                          !_hasTimedOut)
                      ? () => _handleTileSwap(tile)
                      : null,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    final bool canInteract = !_isPreRoundActive &&
        !_isSubmitting &&
        !_completed &&
        !_hasTimedOut;

    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        label: _isReady() ? 'Confirm Word' : 'Fill Letters',
        onPressed: canInteract ? _handleSubmit : null,
        textStyle: const TextStyle(
          fontSize: 24,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  void _loadStage(int index) {
    _stageIndex = index;
    _filledSlots.clear();
    _usedTileIds.clear();
    _disabledTileIds.clear();
    _errorTileId = null;
    _hasTimedOut = false;
    _burningTimer?.cancel();
    _burningTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _preRoundTimer?.cancel();
    _preRoundTimer = null;
    _countdownHideTimer?.cancel();
    _countdownHideTimer = null;
    _timeFreezeTimer?.cancel();
    _timeFreezeTimer = null;
    _timeFreezeActive = false;
    _resumeBurningAfterFreeze = false;
    _timeFreezeRemaining = null;
    _timeFreezeExpiresAt = null;
    _showCountdownOverlay = false;
    _countdownValue = null;
    _resumePreRoundAfterPause = false;
    _swapTilesMode = false;
    _swapTileSelection = null;
    _highlightedSlotIndex = null;
    _boostActivationInProgress = false;
    _activatingBoost = null;

    final stage = _stages[index];
    final answer = stage.answer;
    final extras = List<String>.from(stage.extraLetters);

    if (_modifiers.contains(WheelModifierType.bonusVowels)) {
      _injectBonusVowels(answer, extras);
    }

    _currentSlots = List<WordLetterSlot>.generate(
      answer.length,
      (i) => WordLetterSlot(index: i, character: answer[i]),
    );
    _tiles = _buildTiles(answer, extras);
    _currentHint = stage.hint ??
        (_stageIndex > 0
            ? 'Bonus word: keep your streak alive to double your winnings.'
            : null);

    _timeLimitSeconds = _determineStageTimeLimit(stage.difficulty);
    if (_modifiers.contains(WheelModifierType.timeLimit)) {
      _timeLimitSeconds = _timeLimitSeconds.clamp(15, 45);
    }
    _timeRemaining = _timeLimitSeconds;
    _beginPreRoundCountdown(startValue: 3);
  }

  void _beginPreRoundCountdown({required int startValue}) {
    _preRoundTimer?.cancel();
    _countdownHideTimer?.cancel();
    final int initialValue = startValue <= 0 ? 0 : startValue;
    setState(() {
      _countdownValue = initialValue > 0 ? initialValue : null;
      _showCountdownOverlay = true;
    });
    if (initialValue <= 0) {
      _onPreRoundCountdownFinished();
      return;
    }
    _preRoundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownValue == null) {
        timer.cancel();
        return;
      }
      if (_countdownValue! > 1) {
        setState(() {
          _countdownValue = _countdownValue! - 1;
        });
      } else {
        timer.cancel();
        _onPreRoundCountdownFinished();
      }
    });
  }

  void _onPreRoundCountdownFinished() {
    _preRoundTimer?.cancel();
    _preRoundTimer = null;
    setState(() {
      _countdownValue = null;
    });
    _countdownHideTimer?.cancel();
    _countdownHideTimer = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() {
        _showCountdownOverlay = false;
      });
      _beginStagePlay();
    });
  }

  void _beginStagePlay() {
    if (_isPaused) {
      return;
    }
    if (_countdownTimer == null) {
      _startCountdown();
    }
    if (_modifiers.contains(WheelModifierType.burningTiles) &&
        _burningTimer == null &&
        !_timeFreezeActive) {
      _startBurningTimer();
    }
  }

  void _dismissReward() {
    if (_pendingReward == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _pendingReward = null);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  void _handleTileTap(WordTile tile) {
    if (_isPreRoundActive || _isSubmitting || _completed || _hasTimedOut) return;
    if (_usedTileIds.contains(tile.id) || _disabledTileIds.contains(tile.id)) {
      return;
    }

    if (!tile.isSolution || tile.slotIndex == null) {
      _showInvalidTileFeedback(tile.id);
      return;
    }

    if (_filledSlots.containsKey(tile.slotIndex)) {
      return;
    }

    setState(() {
      _filledSlots[tile.slotIndex!] = tile;
      _usedTileIds.add(tile.id);
    });
  }

  void _handleTileSwap(WordTile tile) {
    if (!_swapTilesMode) return;
    if (_usedTileIds.contains(tile.id) || _disabledTileIds.contains(tile.id)) {
      return;
    }
    if (_swapTileSelection == tile.id) {
      setState(() => _swapTileSelection = null);
      return;
    }
    if (_swapTileSelection == null) {
      setState(() => _swapTileSelection = tile.id);
      return;
    }
    final int firstIndex =
        _tiles.indexWhere((candidate) => candidate.id == _swapTileSelection);
    final int secondIndex = _tiles.indexWhere((candidate) => candidate.id == tile.id);
    if (firstIndex == -1 || secondIndex == -1) {
      setState(() {
        _swapTileSelection = null;
        _swapTilesMode = false;
      });
      return;
    }
    setState(() {
      final tmp = _tiles[firstIndex];
      _tiles[firstIndex] = _tiles[secondIndex];
      _tiles[secondIndex] = tmp;
      _swapTileSelection = null;
      _swapTilesMode = false;
    });
    _showSnack('Tiles swapped.');
  }

  void _clearSlot(int slotIndex) {
    if (_isPreRoundActive) return;
    final tile = _filledSlots.remove(slotIndex);
    if (tile == null) return;
    setState(() => _usedTileIds.remove(tile.id));
  }

  Future<void> _handleBoostPressed(BoostType type) async {
    if (_boostActivationInProgress || _completed) {
      return;
    }
    if (_isPaused) {
      _showSnack('Resume the quiz to use boosts.');
      return;
    }
    if (_isPreRoundActive) {
      _showSnack('Boosts unlock once the round begins.');
      return;
    }
    if (!_canActivateBoost(type)) {
      _showSnack(_boostUnavailableMessage(type));
      return;
    }

    setState(() {
      _boostActivationInProgress = true;
      _activatingBoost = type;
    });

    final success = await ref.read(playerProgressProvider.notifier).consumeBoost(type);
    if (!mounted) {
      return;
    }
    setState(() {
      _boostActivationInProgress = false;
      _activatingBoost = null;
    });

    if (!success) {
      _showSnack('No charges left for that boost.');
      return;
    }

    switch (type) {
      case BoostType.reSpin:
        _applyRespinBoost();
        break;
      case BoostType.revealLetter:
        _applyRevealLetterBoost();
        break;
      case BoostType.swapTiles:
        _applySwapTilesBoost();
        break;
      case BoostType.timeFreeze:
        _applyTimeFreezeBoost();
        break;
      case BoostType.streakShield:
        _applyStreakShieldBoost();
        break;
    }
  }

  void _applyRespinBoost() {
    setState(() {
      _swapTilesMode = false;
      _swapTileSelection = null;
      _filledSlots.clear();
      _usedTileIds.clear();
      _disabledTileIds.clear();
      _errorTileId = null;
      _tiles = List<WordTile>.from(_tiles)..shuffle(_random);
    });
    _showSnack('Tiles reshuffled and fresh letters drawn.');
  }

  void _applyRevealLetterBoost() {
    final availableSlots = _currentSlots
        .where((slot) => !_filledSlots.containsKey(slot.index))
        .toList(growable: false);
    if (availableSlots.isEmpty) {
      _showSnack('All letters are already placed.');
      return;
    }
    final targetSlot =
        availableSlots[_random.nextInt(availableSlots.length)];
    WordTile? tile;
    for (final candidate in _tiles) {
      if (candidate.slotIndex == targetSlot.index &&
          !_usedTileIds.contains(candidate.id)) {
        tile = candidate;
        break;
      }
    }
    if (tile == null) {
      _showSnack('No matching letter available to reveal.');
      return;
    }
    setState(() {
      _swapTilesMode = false;
      _swapTileSelection = null;
      _filledSlots[targetSlot.index] = tile!;
      _usedTileIds.add(tile.id);
      _highlightedSlotIndex = targetSlot.index;
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_highlightedSlotIndex == targetSlot.index) {
        setState(() => _highlightedSlotIndex = null);
      }
    });
    _showSnack('A correct letter has been revealed.');
  }

  void _applySwapTilesBoost() {
    final swapCandidates = _tiles.where((tile) {
      return !_usedTileIds.contains(tile.id) && !_disabledTileIds.contains(tile.id);
    }).length;
    if (swapCandidates < 2) {
      _showSnack('Not enough tiles available to swap.');
      return;
    }
    setState(() {
      _swapTilesMode = true;
      _swapTileSelection = null;
    });
    _showSnack('Select two loose tiles to swap their positions.');
  }

  void _applyTimeFreezeBoost() {
    if (_timeFreezeActive || _hasTimedOut) {
      return;
    }
    final bool burningActive = _burningTimer != null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _timeFreezeTimer?.cancel();
    _burningTimer?.cancel();
    _burningTimer = null;
    _resumeBurningAfterFreeze = burningActive;

    setState(() => _timeFreezeActive = true);
    _showSnack('Timer frozen for 8 seconds.');
    const freezeDuration = Duration(seconds: 8);
    _timeFreezeExpiresAt = DateTime.now().add(freezeDuration);
    _timeFreezeTimer = Timer(freezeDuration, _onTimeFreezeExpired);
  }

  void _onTimeFreezeExpired() {
    if (!mounted) return;
    setState(() {
      _timeFreezeActive = false;
      _timeFreezeExpiresAt = null;
      _timeFreezeRemaining = null;
    });
    if (_resumeBurningAfterFreeze &&
        !_isPaused &&
        _modifiers.contains(WheelModifierType.burningTiles)) {
      _startBurningTimer();
    }
    _resumeBurningAfterFreeze = false;
    if (!_isPaused && !_hasTimedOut && !_isPreRoundActive) {
      _startCountdown();
    }
  }

  void _applyStreakShieldBoost() {
    if (_streakShieldActive) {
      _showSnack('Streak Shield already armed.');
      return;
    }
    setState(() => _streakShieldActive = true);
    _showSnack('Streak Shield armed for the next failure.');
  }

  bool _canActivateBoost(BoostType type) {
    if (_isSubmitting || _completed || _hasTimedOut) {
      return false;
    }
    switch (type) {
      case BoostType.reSpin:
        return !_swapTilesMode && _tiles.isNotEmpty;
      case BoostType.revealLetter:
        return _filledSlots.length < _currentSlots.length;
      case BoostType.swapTiles:
        final candidates = _tiles.where((tile) {
          return !_usedTileIds.contains(tile.id) && !_disabledTileIds.contains(tile.id);
        }).length;
        return !_swapTilesMode && candidates >= 2;
      case BoostType.timeFreeze:
        return !_timeFreezeActive && !_isPreRoundActive && _timeLimitSeconds > 0 && _timeRemaining > 0;
      case BoostType.streakShield:
        return !_streakShieldActive;
    }
  }

  String _boostUnavailableMessage(BoostType type) {
    switch (type) {
      case BoostType.reSpin:
        return 'Wait for the round to begin to reshuffle tiles.';
      case BoostType.revealLetter:
        return 'No empty slots to reveal right now.';
      case BoostType.swapTiles:
        return 'Need at least two unused tiles to swap.';
      case BoostType.timeFreeze:
        return 'Timer must be running to freeze time.';
      case BoostType.streakShield:
        return 'Streak Shield already active.';
    }
  }

  void _showInvalidTileFeedback(String tileId) {
    _errorTimer?.cancel();
    setState(() => _errorTileId = tileId);
    _errorTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _errorTileId = null);
      }
    });
    _showSnack('That letter doesn\'t belong to this word.');
  }

  void _startCountdown() {
    if (_timeLimitSeconds <= 0 ||
        _countdownTimer != null ||
        _timeFreezeActive ||
        _hasTimedOut ||
        _isPaused) {
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        if (_countdownTimer == timer) {
          _countdownTimer = null;
        }
        return;
      }
      if (_timeFreezeActive) {
        return;
      }
      if (_timeRemaining <= 1) {
        timer.cancel();
        if (_countdownTimer == timer) {
          _countdownTimer = null;
        }
        _hasTimedOut = true;
        _handleFailure('Time\'s up! Try again for rewards.');
      } else {
        setState(() => _timeRemaining -= 1);
      }
    });
  }

  void _startBurningTimer() {
    if (_isPaused) {
      return;
    }
    _burningTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted || _completed || _hasTimedOut || _timeFreezeActive || _isPaused) {
        timer.cancel();
        if (_burningTimer == timer) {
          _burningTimer = null;
        }
        return;
      }
      _burnRandomTile();
    });
  }

  void _burnRandomTile() {
    final candidates = _tiles.where((tile) {
      final alreadyUsed = _usedTileIds.contains(tile.id);
      final disabled = _disabledTileIds.contains(tile.id);
      return !alreadyUsed && !disabled && !tile.isSolution;
    }).toList(growable: false);

    if (candidates.isEmpty) {
      return;
    }

    final target = candidates[_random.nextInt(candidates.length)];
    setState(() => _disabledTileIds.add(target.id));
  }

  bool _isReady() => _filledSlots.length == _currentSlots.length;

  Future<void> _finalizeSuccess() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _burningTimer?.cancel();
    _burningTimer = null;
    _timeFreezeTimer?.cancel();
    _timeFreezeTimer = null;
    _preRoundTimer?.cancel();
    _preRoundTimer = null;
    _countdownHideTimer?.cancel();
    _countdownHideTimer = null;
    _showCountdownOverlay = false;
    _countdownValue = null;
    _timeFreezeActive = false;
    _resumeBurningAfterFreeze = false;
    _timeFreezeRemaining = null;
    _timeFreezeExpiresAt = null;
    final notifier = ref.read(playerProgressProvider.notifier);
    await notifier.markWordCompleted(widget.challenge.id);
    await notifier.addXp(_rewardedXp);
    await notifier.addChips(_rewardedChips);
    await notifier.incrementStreak();

    if (!mounted) return;
    setState(() {
      _completed = true;
      _isSubmitting = false;
      _swapTilesMode = false;
      _swapTileSelection = null;
      _highlightedSlotIndex = null;
      _boostActivationInProgress = false;
      _activatingBoost = null;
      _pendingReward = _RewardSummary(
        xp: _rewardedXp,
        chips: _rewardedChips,
      );
    });
  }

  Future<void> _handleFailure(String message) async {
    if (_failureProcessed) return;
    _failureProcessed = true;
    if (_streakShieldActive) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _burningTimer?.cancel();
      _burningTimer = null;
      _preRoundTimer?.cancel();
      _preRoundTimer = null;
      _countdownHideTimer?.cancel();
      _countdownHideTimer = null;
      _timeFreezeTimer?.cancel();
      _timeFreezeTimer = null;
      setState(() {
        _showCountdownOverlay = false;
        _countdownValue = null;
        _streakShieldActive = false;
        _timeFreezeActive = false;
        _timeFreezeExpiresAt = null;
        _timeFreezeRemaining = null;
        _resumeBurningAfterFreeze = false;
        _isSubmitting = false;
        _hasTimedOut = false;
        _swapTilesMode = false;
        _swapTileSelection = null;
        _highlightedSlotIndex = null;
        _boostActivationInProgress = false;
        _activatingBoost = null;
        _failureProcessed = false;
      });
      _showSnack('Streak Shield absorbed the loss! Stage reset.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadStage(_stageIndex);
      });
      return;
    }
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _burningTimer?.cancel();
    _burningTimer = null;
    _preRoundTimer?.cancel();
    _preRoundTimer = null;
    _countdownHideTimer?.cancel();
    _countdownHideTimer = null;
    _timeFreezeTimer?.cancel();
    _timeFreezeTimer = null;
    _timeFreezeActive = false;
    _timeFreezeExpiresAt = null;
    _timeFreezeRemaining = null;
    _resumeBurningAfterFreeze = false;
    _boostActivationInProgress = false;
    _activatingBoost = null;

    final notifier = ref.read(playerProgressProvider.notifier);
    await _applyPenalty();
    await notifier.resetStreak();

    if (!mounted) return;
    setState(() {
      _showCountdownOverlay = false;
      _countdownValue = null;
      _isSubmitting = false;
    });
    _showSnack(message);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _applyPenalty() async {
    final bet = widget.bet ?? 0;
    if (bet <= 0) return;
    final totalPenalty = (bet * widget.penaltyMultiplier).round();
    final notifier = ref.read(playerProgressProvider.notifier);
    if (totalPenalty < bet) {
      await notifier.addChips(bet - totalPenalty);
    } else if (totalPenalty > bet) {
      await notifier.spendChips(totalPenalty - bet);
    }
  }

  Future<bool?> _showDoubleDownPrompt() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Double Down?'),
        content: const Text('Continue to the next word for a bigger payout? Failing the next word forfeits this reward.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bank reward'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _injectBonusVowels(String answer, List<String> extras) {
    const vowels = ['A', 'E', 'I', 'O', 'U'];
    for (final vowel in vowels) {
      if (!answer.contains(vowel) && !extras.contains(vowel)) {
        extras.add(vowel);
      }
      if (extras.length >= 3) break;
    }
  }

  List<WordTile> _buildTiles(String answer, List<String> extras) {
    final tiles = <WordTile>[];
    for (var i = 0; i < answer.length; i++) {
      final char = answer[i];
      tiles.add(
        WordTile(
          id: 'solution_${i}_$char',
          character: char,
          slotIndex: i,
          isSolution: true,
        ),
      );
    }
    for (var i = 0; i < extras.length; i++) {
      final char = extras[i].toUpperCase();
      tiles.add(
        WordTile(
          id: 'extra_${i}_$char',
          character: char,
          slotIndex: null,
          isSolution: false,
        ),
      );
    }
    tiles.shuffle(_random);
    return tiles;
  }

  int _determineStageTimeLimit(String difficulty) {
    final length = _stage.answer.length;
    switch (difficulty.toLowerCase()) {
      case 'expert':
        return (20 + length * 2).clamp(15, 75).toInt();
      case 'hard':
        return (25 + length * 2).clamp(20, 90).toInt();
      case 'medium':
        return (35 + length * 2).clamp(25, 100).toInt();
      default:
        return (45 + length * 2).clamp(30, 120).toInt();
    }
  }

  int get _rewardedXp =>
      (_applyMultiplier(_baseXpReward * (_stageIndex + 1), widget.rewardMultiplier))
          .round();

  int get _rewardedChips =>
      (_applyMultiplier(_baseChipReward * (_stageIndex + 1), widget.rewardMultiplier))
          .round();

  double _applyMultiplier(int value, double multiplier) {
    final result = value * multiplier;
    return result < 0 ? 0 : result;
  }

  int _computeBaseXp(String difficulty, int length) {
    switch (difficulty.toLowerCase()) {
      case 'expert':
        return 20 + length * 4;
      case 'hard':
        return 15 + length * 3;
      case 'medium':
        return 12 + length * 3;
      default:
        return 8 + length * 2;
    }
  }

  int _computeBaseChips(String difficulty, int length) {
    switch (difficulty.toLowerCase()) {
      case 'expert':
        return 18 + length;
      case 'hard':
        return 12 + length;
      case 'medium':
        return 9 + length;
      default:
        return 6 + length;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(int seconds) {
    final clamped = seconds.clamp(0, 5999).toInt();
    final minutes = clamped ~/ 60;
    final secs = clamped % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _StageData {
  const _StageData({
    required this.answer,
    required this.difficulty,
    required this.extraLetters,
    this.hint,
  });

  final String answer;
  final String difficulty;
  final List<String> extraLetters;
  final String? hint;
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({
    required this.value,
  });

  final int? value;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          opacity: value == null ? 0.0 : 1.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black.withOpacity(0.75),
              ),

              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                      reverseCurve: Curves.easeInCubic,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.1).animate(curved),
                        child: child,
                      ),
                    );
                  },
                  child: value == null
                      ? const SizedBox.shrink()
                      : StrokeText(
                          key: ValueKey<int>(value!),
                          text: value!.toString(),
                          fontSize: 120,
                          strokeColor: const Color(0xFFD8D5EA),
                          fillColor: Colors.white,
                          shadowColor: const Color(0xFF46557B),
                          shadowBlurRadius: 6,
                          shadowOffset: const Offset(0, 4),
                          textAlign: TextAlign.center,
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


class _RewardSummary {
  const _RewardSummary({
    required this.xp,
    required this.chips,
  });

  final int xp;
  final int chips;

  bool get hasXp => xp > 0;
  bool get hasChips => chips > 0;
}

class _RewardCelebration extends StatelessWidget {
  const _RewardCelebration({
    required this.summary,
    required this.onDismiss,
    this.chipRewardImage,
    this.xpRewardImage,
  });

  final _RewardSummary summary;
  final VoidCallback onDismiss;
  final String? chipRewardImage;
  final String? xpRewardImage;

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[];
    if (summary.hasXp) {
      stats.add(_RewardMetric(
        leading: xpRewardImage != null
            ? Image.asset(
                xpRewardImage!,
                height: 28,
                fit: BoxFit.contain,
              )
            : const Icon(Icons.star, color: Color(0xFFFFAF28), size: 24),
        label: 'XP Earned',
        value: '+${summary.xp}',
      ));
    }
    if (summary.hasChips) {
      if (stats.isNotEmpty) {
        stats.add(const SizedBox(height: 12));
      }
      stats.add(_RewardMetric(
        leading: chipRewardImage != null
            ? Image.asset(
                chipRewardImage!,
                height: 28,
                fit: BoxFit.contain,
              )
            : const Icon(Icons.casino, color: Color(0xFFFFAF28), size: 24),
        label: 'Chips Won',
        value: '+${summary.chips}',
      ));
    }

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: onDismiss,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  Images.winConfetii,
                  fit: BoxFit.cover,
                ),
                Container(color: Colors.black.withOpacity(0.25)),
              ],
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: onDismiss,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  final double scale = 0.85 + (0.15 * value);
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StrokeText(
                        text: 'Word Complete!',
                        fontSize: 36,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Collect your rewards before the next challenge.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontFamily: 'Cookies',
                          height: 1.3,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (stats.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ...stats,
                      ] else ...[
                        const SizedBox(height: 20),
                        const Text(
                          'No bonus rewards this time, but you kept your streak alive!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Collect Rewards',
                        onPressed: onDismiss,
                        textStyle: const TextStyle(fontSize: 24),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardMetric extends StatelessWidget {
  const _RewardMetric({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Center(child: leading),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Cookies',
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFAF28),
              fontSize: 16,
              fontFamily: 'Cookies',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color tone = highlight ? const Color(0xFFFFAF28) : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0x33FFAF28) : const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? const Color(0xFFFFAF28) : Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tone, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: tone, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onShop,
    required this.onStats,
    required this.onEndQuiz,
  });

  final VoidCallback onResume;
  final VoidCallback onShop;
  final VoidCallback onStats;
  final VoidCallback onEndQuiz;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          const ModalBarrier(
            color: Color(0xDD000000), // сделал более темным - с AA на DD
            dismissible: false
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 66),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const StrokeText(
                    text: 'Paused',
                    fontSize: 36,
                    strokeColor: Color(0xFFD8D5EA),
                    fillColor: Colors.white,
                    shadowColor: Color(0xFF46557B),
                    shadowBlurRadius: 4,
                    shadowOffset: Offset(0, 3),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Resume',
                    onPressed: onResume,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Shop',
                    onPressed: onShop,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Stats',
                    onPressed: onStats,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'End Quiz',
                    onPressed: onEndQuiz,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 24,
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
}

class _BoostsOverlay extends StatelessWidget {
  const _BoostsOverlay({
    required this.inventory,
    required this.onBoostSelected,
    required this.onDismiss,
    required this.canActivate,
    required this.infoBuilder,
  });

  final Map<BoostType, int> inventory;
  final void Function(BoostType) onBoostSelected;
  final VoidCallback onDismiss;
  final bool Function(BoostType) canActivate;
  final BoostInfo Function(BoostType) infoBuilder;

  @override
  Widget build(BuildContext context) {
    final double listHeight =
        (MediaQuery.sizeOf(context).height * 0.5).clamp(220.0, 420.0);
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          const ModalBarrier(color: Color(0xAA000000), dismissible: false),
          Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Color(0xFF261B40),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0x40FFFFFF)),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 10)),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const StrokeText(
                          text: 'Boosts',
                          fontSize: 28,
                          textAlign: TextAlign.left,
                        ),
                        IconButton(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Activate a boost instantly to tilt the odds in your favor.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: listHeight,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            for (final type in BoostType.values)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _BoostOptionTile(
                                  info: infoBuilder(type),
                                  count: inventory[type] ?? 0,
                                  enabled: (inventory[type] ?? 0) > 0 && canActivate(type),
                                  onTap: () => onBoostSelected(type),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostOptionTile extends StatelessWidget {
  const _BoostOptionTile({
    required this.info,
    required this.count,
    required this.enabled,
    this.onTap,
  });

  final BoostInfo info;
  final int count;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = info.accent;
    final bool canTap = enabled && onTap != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withOpacity(0.24),
              const Color(0x221F1039),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.45), accent.withOpacity(0.14)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(info.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              info.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontFamily: 'Cookies',
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.24),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              'Owned: $count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 220,
                child: PrimaryButton(
                  uppercase: false,
                  onPressed: canTap ? onTap : null,
                  enabled: canTap,
                  busy: false,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: canTap ? Colors.transparent : Colors.white.withOpacity(0.15),
                  backgroundGradient: canTap
                      ? LinearGradient(
                          colors: [accent.withOpacity(0.95), accent.withOpacity(0.7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  borderColor: accent,
                  disabledBorderColor: Colors.white24,
                  child: Text(
                    canTap ? 'Use boost'.toUpperCase() : 'Unavailable'.toUpperCase(),
                    style: TextStyle(
                      color: canTap ? Colors.white : Colors.white54,
                      fontSize: 18,
                      fontFamily: 'Cookies',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.isFilled,
    this.letter,
    this.isHighlighted = false,
    this.onTap,
    required this.colorScheme,
  });

  final bool isFilled;
  final String? letter;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final Color filledBackground = colorScheme.secondaryContainer.withOpacity(0.95);
    final Color emptyBackground = Colors.white.withOpacity(0.05);
    final Color highlightBorder = colorScheme.tertiary.withOpacity(0.85);
    final Color filledBorder = colorScheme.secondary.withOpacity(0.75);
    final Color emptyBorder = Colors.white.withOpacity(0.16);
    final Color background = isFilled ? filledBackground : emptyBackground;
    final Color border = isHighlighted
        ? highlightBorder
        : isFilled
            ? filledBorder
            : emptyBorder;
    final Color placeholderColor = Colors.white.withOpacity(0.22);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2),
        ),
        alignment: Alignment.center,
        child: letter == null
            ? Text(
                '—',
                style: TextStyle(
                  color: placeholderColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              )
            : Text(
                letter!,
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.tile,
    required this.isUsed,
    required this.isDisabled,
    required this.isError,
    required this.isSwapMode,
    required this.isSwapSelectable,
    required this.isSwapSelected,
    required this.colorScheme,
    this.onTap,
  });

  final WordTile tile;
  final bool isUsed;
  final bool isDisabled;
  final bool isError;
  final bool isSwapMode;
  final bool isSwapSelectable;
  final bool isSwapSelected;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool canTap = onTap != null;
    final bool highlightSwap = isSwapMode && isSwapSelectable;
    final Color activeBorder = colorScheme.primary.withOpacity(0.75);
    final Color idleBorder = Colors.white.withOpacity(0.16);
    final Color usedBorder = Colors.white.withOpacity(0.08);
    final Color swapBorder = colorScheme.secondary.withOpacity(0.85);
    final Color highlightBorder = colorScheme.tertiary.withOpacity(0.8);
    final Color errorBorder = colorScheme.error.withOpacity(0.9);
    final Color borderColor = isError
        ? errorBorder
        : isSwapSelected
            ? swapBorder
            : highlightSwap
                ? highlightBorder
                : isUsed
                    ? usedBorder
                    : activeBorder;
    final Color baseBackground = Color.alphaBlend(
      colorScheme.surfaceVariant.withOpacity(0.55),
      Colors.black.withOpacity(0.7),
    );
    final Color background = isUsed
        ? Colors.white.withOpacity(0.05)
        : isError
            ? colorScheme.error.withOpacity(0.22)
            : isSwapSelected
                ? colorScheme.secondaryContainer.withOpacity(0.32)
                : isSwapMode && !highlightSwap
                    ? Colors.white.withOpacity(0.03)
                    : baseBackground;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: canTap ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            tile.character,
            style: TextStyle(
              color: isError
                  ? colorScheme.error
                  : colorScheme.onSurface.withOpacity(isDisabled ? 0.5 : 1.0),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
