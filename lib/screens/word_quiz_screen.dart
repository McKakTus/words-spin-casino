import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/boost_catalog.dart';
import '../models/player_progress.dart';
import '../models/wheel_segment.dart';
import '../models/word_challenge.dart';
import '../providers/player_progress_provider.dart';
import 'boost_shop_screen.dart';
import 'stats_screen.dart';
enum WordQuizMode { standard, daily }

class WordQuizScreen extends ConsumerStatefulWidget {
  const WordQuizScreen({
    super.key,
    required this.challenge,
    required this.modifiers,
    this.mode = WordQuizMode.standard,
    this.totalDailyWords,
    this.segmentId,
    this.bet,
    this.rewardMultiplier = 1.0,
    this.penaltyMultiplier = 1.0,
  });

  final WordChallenge challenge;
  final List<WheelModifierType> modifiers;
  final WordQuizMode mode;
  final int? totalDailyWords;
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

  late List<WordLetterSlot> _currentSlots;
  late List<WordTile> _tiles;
  String? _currentHint;

  Timer? _errorTimer;
  Timer? _countdownTimer;
  Timer? _burningTimer;
  Timer? _introTimer;
  Timer? _timeFreezeTimer;

  int _stageIndex = 0;
  int _timeLimitSeconds = 0;
  int _timeRemaining = 0;
  bool _hasTimedOut = false;
  bool _isSubmitting = false;
  bool _completed = false;
  bool _failureProcessed = false;
  bool _showIntro = true;
  bool _timeFreezeActive = false;
  bool _resumeBurningAfterFreeze = false;
  bool _resumeCountdownAfterPause = false;
  bool _resumeBurningAfterPause = false;
  bool _resumeIntroAfterPause = false;
  bool _isPaused = false;
  bool _showPauseOverlay = false;
  bool _showBoostsOverlay = false;
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

  @override
  void initState() {
    super.initState();
    _modifiers = widget.modifiers.toSet();
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
    _introTimer?.cancel();
    _timeFreezeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProgressAsync = ref.watch(playerProgressProvider);
    final playerProgress = playerProgressAsync.value;
    final statusChips = _statusChips();
    final bool canOpenBoostOverlay = playerProgress != null &&
        !_showBoostsOverlay &&
        !_showPauseOverlay &&
        _pendingReward == null &&
        !_boostActivationInProgress &&
        !_isSubmitting &&
        !_completed &&
        !_hasTimedOut;

    if (playerProgress == null && _showBoostsOverlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _showBoostsOverlay = false);
      });
    }

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
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.pause_circle_filled, size: 28),
            color: Colors.white,
            onPressed: _handlePausePressed,
            tooltip: 'Pause',
          ),
          title: Text(
            widget.challenge.category.toUpperCase(),
            style: const TextStyle(fontSize: 24),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bolt_rounded, size: 26),
              color: Colors.white,
              tooltip: 'Boosts',
              onPressed: canOpenBoostOverlay ? _openBoostsOverlay : null,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!_showIntro) ...[
                      _buildTimerBadge(),
                      if (statusChips.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: statusChips,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildStageIndicator(),
                      const SizedBox(height: 16),
                      _buildHintBanner(),
                    ],
                    if (_showIntro) const SizedBox(height: 32),
                    _buildSlotsRow(),
                    const SizedBox(height: 18),
                    const Text(
                      'Beat the timer: tap letters to fill slots, tap a slot to clear.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Center(child: _buildTilesGrid()),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildActions(context),
                  ],
                ),
              ),
              if (_showIntro)
                _IntroOverlay(
                  onDismiss: _dismissIntro,
                  child: _IntroPopup(
                    segment: widget.segmentId,
                    bet: widget.bet ?? 0,
                    rewardMultiplier: widget.rewardMultiplier,
                    penaltyMultiplier: widget.penaltyMultiplier,
                    modifiers: _modifiers,
                    xpReward: _rewardedXp,
                    chipReward: _rewardedChips,
                  ),
                ),
              if (_pendingReward != null)
                _RewardCelebration(
                  summary: _pendingReward!,
                  onDismiss: _dismissReward,
                ),
              if (_showBoostsOverlay && playerProgress != null)
                _BoostsOverlay(
                  inventory: playerProgress.boostInventory,
                  onBoostSelected: _activateBoostFromOverlay,
                  onDismiss: () => setState(() => _showBoostsOverlay = false),
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
          ),
        ),
      ),
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
    if (_showIntro) {
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
    _introTimer?.cancel();
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

  Widget _buildHintBanner() {
    if (_currentHint == null || _currentHint!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFF6D736), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _currentHint!,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
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
      setState(() => _showBoostsOverlay = false);
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
    _resumeIntroAfterPause = _showIntro && _introTimer != null;

    _countdownTimer?.cancel();
    _countdownTimer = null;
    _burningTimer?.cancel();
    _burningTimer = null;
    _introTimer?.cancel();
    _introTimer = null;

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
        _resumeCountdownAfterPause && !_showIntro && !_timeFreezeActive;
    final bool shouldRestartBurning =
        (_resumeBurningAfterPause ||
                (_resumeBurningAfterFreeze && !_timeFreezeActive)) &&
            _modifiers.contains(WheelModifierType.burningTiles);
    final bool shouldRestartIntro = _resumeIntroAfterPause && _showIntro;

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

    if (shouldRestartIntro && _introTimer == null) {
      _introTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        _dismissIntro();
      });
    }

    if (shouldRestartCountdown && _countdownTimer == null) {
      _startCountdown();
    }

    if (shouldRestartBurning && _burningTimer == null) {
      _startBurningTimer();
    }

    _resumeCountdownAfterPause = false;
    _resumeBurningAfterPause = false;
    _resumeIntroAfterPause = false;
  }

  void _openBoostsOverlay() {
    if (_showBoostsOverlay || _showPauseOverlay || _pendingReward != null) {
      return;
    }
    setState(() => _showBoostsOverlay = true);
  }

  void _activateBoostFromOverlay(BoostType type) {
    setState(() => _showBoostsOverlay = false);
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

  Widget _buildStageIndicator() {
    if (_totalStages <= 1) return const SizedBox.shrink();
    return Text(
      'Stage ${_stageIndex + 1} of $_totalStages',
      style: const TextStyle(color: Colors.white70, fontSize: 13),
    );
  }

  Widget _buildTimerBadge() {
    if (_showIntro) return const SizedBox.shrink();
    if (_timeLimitSeconds <= 0) return const SizedBox.shrink();
    final progress = _timeLimitSeconds == 0
        ? 0.0
        : (_timeRemaining.clamp(0, _timeLimitSeconds)) / _timeLimitSeconds;
    final Color baseColor = _hasTimedOut
        ? const Color(0xFFFF6E6E)
        : progress > 0.5
            ? const Color(0xFF00F5A0)
            : progress > 0.25
                ? const Color(0xFFFFAF28)
                : const Color(0xFFFF6E6E);

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value: _hasTimedOut ? 0 : progress,
                minHeight: 10,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(baseColor),
              ),
              Text(
                _formatTime(_timeRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

  Widget _buildSlotsRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: _currentSlots
          .map(
            (slot) => _SlotChip(
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

  Widget _buildTilesGrid() {
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

  Widget _buildActions(BuildContext context) {
    if (_showIntro) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFAF28),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontFamily: 'Cookies', fontSize: 22),
        ),
        onPressed: null,
        child: const Text('Get Ready...'),
      );
    }

    if (_hasTimedOut) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF6E6E),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontFamily: 'Cookies', fontSize: 22),
        ),
        onPressed: () => _handleFailure('Time\'s up! Try again for rewards.'),
        child: const Text('Time\'s Up'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isSubmitting || _completed
                ? null
                : _usedTileIds.isEmpty
                    ? null
                    : _resetSelection,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFAF28),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontFamily: 'Cookies', fontSize: 22),
            ),
            onPressed: _isSubmitting || _completed ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                  )
                : Text(_isReady() ? 'Confirm Word' : 'Fill Letters'),
          ),
        ),
      ],
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
    _introTimer?.cancel();
    _introTimer = null;
    _timeFreezeTimer?.cancel();
    _timeFreezeTimer = null;
    _timeFreezeActive = false;
    _resumeBurningAfterFreeze = false;
    _timeFreezeRemaining = null;
    _timeFreezeExpiresAt = null;
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
    setState(() => _showIntro = true);
    _introTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      _dismissIntro();
    });
  }

  void _dismissIntro() {
    if (!_showIntro) {
      return;
    }
    _introTimer?.cancel();
    setState(() => _showIntro = false);
    if (_countdownTimer == null && !_isPaused) {
      _startCountdown();
    }
    if (_modifiers.contains(WheelModifierType.burningTiles) &&
        _burningTimer == null &&
        !_isPaused) {
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

  void _resetSelection() {
    setState(() {
      _filledSlots.clear();
      _usedTileIds.clear();
      _highlightedSlotIndex = null;
      _swapTilesMode = false;
      _swapTileSelection = null;
    });
  }

  void _handleTileTap(WordTile tile) {
    if (_showIntro || _isSubmitting || _completed || _hasTimedOut) return;
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
    if (_showIntro) return;
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
    if (_showIntro) {
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
    if (!_isPaused && !_hasTimedOut && !_showIntro) {
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
        return !_timeFreezeActive && !_showIntro && _timeLimitSeconds > 0 && _timeRemaining > 0;
      case BoostType.streakShield:
        return !_streakShieldActive;
    }
  }

  String _boostUnavailableMessage(BoostType type) {
    switch (type) {
      case BoostType.reSpin:
        return 'Finish the intro and keep playing to reshuffle tiles.';
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
    _introTimer?.cancel();
    _introTimer = null;
    _timeFreezeTimer?.cancel();
    _timeFreezeTimer = null;
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
      _introTimer?.cancel();
      _introTimer = null;
      _timeFreezeTimer?.cancel();
      _timeFreezeTimer = null;
      setState(() {
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
    _introTimer?.cancel();
    _introTimer = null;
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
    setState(() => _isSubmitting = false);
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

class _IntroOverlay extends StatelessWidget {
  const _IntroOverlay({required this.child, required this.onDismiss});

  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _IntroPopup extends StatelessWidget {
  const _IntroPopup({
    required this.segment,
    required this.bet,
    required this.rewardMultiplier,
    required this.penaltyMultiplier,
    required this.modifiers,
    required this.xpReward,
    required this.chipReward,
  });

  final WheelSegmentId? segment;
  final int bet;
  final double rewardMultiplier;
  final double penaltyMultiplier;
  final Set<WheelModifierType> modifiers;
  final int xpReward;
  final int chipReward;

  @override
  Widget build(BuildContext context) {
    final label = segment?.name.toUpperCase() ?? 'STANDARD';
    final summary = [
      'Stake $bet chips',
      '+$xpReward XP',
      '+$chipReward chips',
      'Reward ×${rewardMultiplier.toStringAsFixed(2)}',
      'Penalty ×${penaltyMultiplier.toStringAsFixed(2)}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFe58923), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFAF28),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (modifiers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: modifiers
                  .map(
                    (modifier) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x332196F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x552196F3)),
                      ),
                      child: Text(
                        modifier.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Get ready! The round begins shortly...',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
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
  });

  final _RewardSummary summary;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[];
    if (summary.hasXp) {
      stats.add(_RewardMetric(
        icon: Icons.auto_awesome,
        label: 'XP Earned',
        value: '+${summary.xp}',
      ));
    }
    if (summary.hasChips) {
      if (stats.isNotEmpty) {
        stats.add(const SizedBox(height: 12));
      }
      stats.add(_RewardMetric(
        icon: Icons.casino,
        label: 'Chips Won',
        value: '+${summary.chips}',
      ));
    }

    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ModalBarrier(
            color: Colors.black.withValues(alpha: 0.75),
            dismissible: true,
            onDismiss: onDismiss,
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
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFFFFAF28), size: 52),
                  const SizedBox(height: 12),
                  const Text(
                    'Word Complete!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Collect your rewards before the next challenge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
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
                  const SizedBox(height: 24),
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
}

class _RewardMetric extends StatelessWidget {
  const _RewardMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
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
              fontWeight: FontWeight.w600,
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
          const ModalBarrier(color: Color(0xAA000000), dismissible: false),
          Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFAF28), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 14)),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Paused',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                    label: const Text('Resume'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFAF28),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onShop,
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Shop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onStats,
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: const Text('Stats'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onEndQuiz,
                    icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
                    label: const Text('End Quiz'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ModalBarrier(
            color: const Color(0xAA000000),
            dismissible: true,
            onDismiss: onDismiss,
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFAF28), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 14)),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFFFFAF28)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Boosts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...BoostType.values.map((type) {
                    final count = inventory[type] ?? 0;
                    final info = infoBuilder(type);
                    final bool enabled = count > 0 && canActivate(type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BoostOptionTile(
                        icon: info.icon,
                        title: info.label,
                        description: info.description,
                        count: count,
                        enabled: enabled,
                        accent: info.accent,
                        onTap: enabled ? () => onBoostSelected(type) : null,
                      ),
                    );
                  }),
                ],
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
    required this.icon,
    required this.title,
    required this.description,
    required this.count,
    required this.enabled,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final int count;
  final bool enabled;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: enabled ? accent : Colors.white12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: enabled ? accent : accent.withValues(alpha: 0.4), size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (enabled ? accent : accent.withValues(alpha: 0.4)).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '×$count',
                          style: TextStyle(
                            color: enabled ? accent : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: enabled ? Colors.white70 : Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
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
  });

  final bool isFilled;
  final String? letter;
  final bool isHighlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = isFilled ? const Color(0xFFFFAF28) : const Color(0xFF232323);
    final Color border = isHighlighted
        ? const Color(0xFF00F5A0)
        : isFilled
            ? const Color(0xFFE58923)
            : Colors.white24;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2),
          boxShadow: isFilled
              ? const [
              BoxShadow(color: Color(0x33FFA500), blurRadius: 10, offset: Offset(0, 6)),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: letter == null
            ? const Text(
                '—',
                style: TextStyle(color: Colors.white30, fontSize: 20, fontWeight: FontWeight.bold),
              )
            : Text(
                letter!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
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
    this.onTap,
  });

  final WordTile tile;
  final bool isUsed;
  final bool isDisabled;
  final bool isError;
  final bool isSwapMode;
  final bool isSwapSelectable;
  final bool isSwapSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool canTap = onTap != null;
    final bool highlightSwap = isSwapMode && isSwapSelectable;
    final Color borderColor = isError
        ? const Color(0xFFFF6E6E)
        : isSwapSelected
            ? const Color(0xFFFFAF28)
            : highlightSwap
                ? const Color(0xFF00F5A0)
                : isUsed
                    ? Colors.white10
                    : Colors.white24;
    final Color background = isUsed
        ? const Color(0xFF1C1C1C)
        : isError
            ? const Color(0x33FF6E6E)
            : isSwapSelected
                ? const Color(0x33FFAF28)
                : isSwapMode && !highlightSwap
                    ? const Color(0x22111111)
                    : const Color(0xFF2A2A2A);

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: canTap ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 6)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            tile.character,
            style: TextStyle(
              color: isError ? const Color(0xFFFF8686) : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
