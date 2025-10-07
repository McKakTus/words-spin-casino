import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/boost_catalog.dart';
import '../helpers/image_paths.dart';

import '../widgets/header.dart';

import '../models/player_progress.dart';
import '../models/word_challenge.dart';

import '../providers/player_progress_provider.dart';
import '../providers/word_providers.dart';
import '../providers/storage_providers.dart';

import 'boost_shop_screen.dart';
import 'create_account_screen.dart';
import 'login_screen.dart';

const int _kInitialChipBaseline = 250;

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  static const routeName = '/stats';

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _isRedirecting = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);
    final wordsAsync = ref.watch(wordChallengesProvider);
    final progressAsync = ref.watch(playerProgressProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withAlpha(66)),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              Expanded(
                child: progressAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorState(message: e.toString()),
                  data: (PlayerProgress progress) {
                    return profileAsync.when(
                      data: (profile) {
                        if (profile == null) {
                          _redirectToAuth();
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return wordsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) =>
                              _ErrorState(message: e.toString()),
                          data: (List<WordChallenge> words) {
                            return Column(
                              children: [
                                ProfileHeader(
                                  userName: profile.name,
                                  avatarIndex: profile.avatarIndex,
                                  progress: progress,
                                  onStatsTap: () =>
                                      Navigator.of(context).pop(),
                                ),
                                Expanded(
                                  child: _StatsContent(
                                    userName: profile.name,
                                    avatarIndex: profile.avatarIndex,
                                    progress: progress,
                                    words: words,
                                    onResetPressed: () =>
                                        _handleReset(context, ref),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          _ErrorState(message: e.toString()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.userName,
    required this.avatarIndex,
    required this.progress,
    required this.words,
    required this.onResetPressed,
  });

  final String userName;
  final int avatarIndex;
  final PlayerProgress progress;
  final List<WordChallenge> words;
  final Future<void> Function() onResetPressed;

  static const Color _accent = Color(0xFFFFAF28);
  static const Color _cardColor = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    final int totalWords = words.length;
    final int completedWords = progress.completedWordIds.length.clamp(
      0,
      totalWords,
    ).toInt();
    final int remainingWords = (totalWords - completedWords).clamp(
      0,
      totalWords,
    ).toInt();
    final completionRate = totalWords == 0 ? 0.0 : completedWords / totalWords;

    final wordMap = {
      for (final word in words) word.id: word,
    };

    final completedCategories = progress.completedWordIds
        .map((id) => wordMap[id]?.category.trim())
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet();

    final totalCategories = words
        .map((word) => word.category.trim())
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    final averageXp = completedWords == 0
        ? 0
        : (progress.xp / completedWords).floor();
    final totalBoosts =
        progress.boostInventory.values.fold<int>(0, (sum, value) => sum + value);
    final int activeStreak = progress.streak;

    final achievements = _buildAchievements(
      completedWords: completedWords,
      completedCategories: completedCategories.length,
      xp: progress.xp,
      chips: progress.chips,
    );

    final stats = [
      _StatMetric(
        label: 'Words Solved',
        value: completedWords.toString(),
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF00F5A0),
      ),
      _StatMetric(
        label: 'Remaining',
        value: remainingWords.toString(),
        icon: Icons.lock_clock,
        accent: const Color(0xFF4C6FFF),
      ),
      _StatMetric(
        label: 'XP Earned',
        value: progress.xp.toString(),
        icon: Icons.auto_awesome,
        accent: _accent,
      ),
      _StatMetric(
        label: 'Chips Banked',
        value: progress.chips.toString(),
        icon: Icons.savings_outlined,
        accent: const Color(0xFFFF6FB5),
      ),
      _StatMetric(
        label: 'Categories',
        value: '${completedCategories.length}/$totalCategories',
        icon: Icons.grid_view_rounded,
        accent: const Color(0xFF00BBF9),
      ),
      _StatMetric(
        label: 'Avg XP / Word',
        value: averageXp.toString(),
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF9DFF3B),
      ),
      _StatMetric(
        label: 'Active Streak',
        value: activeStreak.toString(),
        icon: Icons.local_fire_department,
        accent: const Color(0xFFFF8A65),
      ),
      _StatMetric(
        label: 'Boosts Owned',
        value: totalBoosts.toString(),
        icon: Icons.bolt_rounded,
        accent: const Color(0xFFFFAF28),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JackpotProgressSection(progress: progress.jackpotProgress),
          const SizedBox(height: 28),
          Text(
            'Word Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _glassDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completion',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(completionRate * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 12,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    _ProgressChip(
                      label: 'Total words',
                      value: totalWords.toString(),
                      icon: Icons.playlist_add_check_rounded,
                    ),
                    _ProgressChip(
                      label: 'Completed',
                      value: completedWords.toString(),
                      icon: Icons.bolt_rounded,
                    ),
                    _ProgressChip(
                      label: 'Remaining',
                      value: remainingWords.toString(),
                      icon: Icons.flag_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Key Word Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _StatsGrid(stats: stats),
          const SizedBox(height: 28),
          _BoostInventorySection(
            inventory: progress.boostInventory,
            onShopTap: () =>
                Navigator.of(context).pushNamed(BoostShopScreen.routeName),
          ),
          const SizedBox(height: 28),
          Text(
            'Word Achievements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _AchievementsList(achievements: achievements),

          const SizedBox(height: 28),
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFe58923),
                    width: 1,
                  ),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  await onResetPressed();
               },
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFAF28), size: 20),
                label: const Text(
                  'Reset Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 44),
        ],
      ),
    );
  }

  List<_AchievementData> _buildAchievements({
    required int completedWords,
    required int completedCategories,
    required int xp,
    required int chips,
  }) {
    return [
      _AchievementData(
        title: 'First Spin',
        description: 'Solve your first word',
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFFFFF066),
        unlocked: completedWords >= 1,
      ),
      _AchievementData(
        title: 'Word Explorer',
        description: 'Solve 10 words',
        icon: Icons.travel_explore_rounded,
        accent: const Color(0xFF4ADE80),
        unlocked: completedWords >= 10,
      ),
      _AchievementData(
        title: 'Category Collector',
        description: 'Master 5 categories',
        icon: Icons.grid_view_rounded,
        accent: const Color(0xFF00BBF9),
        unlocked: completedCategories >= 5,
      ),
      _AchievementData(
        title: 'Rising Star',
        description: 'Earn 800 XP overall',
        icon: Icons.stacked_line_chart_rounded,
        accent: const Color(0xFFFF6FB5),
        unlocked: xp >= 800,
      ),
      _AchievementData(
        title: 'Savings Stash',
        description: 'Save up 750 chips',
        icon: Icons.savings_rounded,
        accent: const Color(0xFFFFAF28),
        unlocked: chips >= _kInitialChipBaseline + 500,
      ),
    ];
  }
}

Future<void> _handleReset(BuildContext context, WidgetRef ref) async {
  final shouldReset =
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Reset progress?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'This clears solved words, XP, and chips. Ready to start fresh?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFAF28),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        ),
      ) ??
      false;

  if (!shouldReset) return;

  await ref.read(playerProgressProvider.notifier).resetProgress();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Progress reset. Spin the wheel for fresh words!'),
    ),
  );
}

class _JackpotProgressSection extends StatelessWidget {
  const _JackpotProgressSection({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final double normalized = (progress.clamp(0, 100)) / 100.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.casino, color: Color(0xFFFFAF28)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jackpot Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${progress.clamp(0, 100)}%',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 14,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFAF28)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Fill the meter by winning spins. Reaching 100% drops bonus chips and boosts.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BoostInventorySection extends StatelessWidget {
  const _BoostInventorySection({
    required this.inventory,
    required this.onShopTap,
  });

  final Map<BoostType, int> inventory;
  final VoidCallback onShopTap;

  @override
  Widget build(BuildContext context) {
    final boostTiles = BoostCatalog.all()
        .map((info) => _BoostInventoryTile(
              info: info,
              count: inventory[info.type] ?? 0,
            ))
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white70, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Boost Inventory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onShopTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAF28),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: const Text(
                  'Open Shop',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: boostTiles,
          ),
        ],
      ),
    );
  }
}

class _BoostInventoryTile extends StatelessWidget {
  const _BoostInventoryTile({required this.info, required this.count});

  final BoostInfo info;
  final int count;

  @override
  Widget build(BuildContext context) {
    final Color accent = info.accent;
    return Container(
      width: MediaQuery.sizeOf(context).width / 2 - 28,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: accent.withAlpha(34),
                ),
                child: Icon(info.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            info.description,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Owned: $count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<_StatMetric> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats
          .map((stat) => _StatCard(metric: stat))
          .toList(growable: false),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.metric});

  final _StatMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width / 2 - 28,
      padding: const EdgeInsets.all(18),
      decoration: _glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: metric.accent.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: metric.accent, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  const _AchievementsList({required this.achievements});

  final List<_AchievementData> achievements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration,
      child: Column(
        children: achievements
            .map(
              (achievement) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _AchievementTile(data: achievement),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.data});

  final _AchievementData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.accent.withAlpha(41),
            border: Border.all(color: data.accent.withAlpha(102)),
          ),
          child: Icon(data.icon, color: data.accent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.description,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(
          data.unlocked ? Icons.check_circle : Icons.lock_outline,
          color: data.unlocked ? data.accent : Colors.white24,
        ),
      ],
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AchievementData {
  const _AchievementData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.unlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final bool unlocked;
}

class _StatMetric {
  const _StatMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
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

const BoxDecoration _glassDecoration = BoxDecoration(
  color: _StatsContent._cardColor,
  borderRadius: BorderRadius.all(Radius.circular(24)),
  border: Border.fromBorderSide(BorderSide(color: Colors.white12)),
  boxShadow: [
    BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 1)),
  ],
);
