import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../models/player_progress.dart';
import '../models/quiz_question.dart';

import '../providers/player_progress_provider.dart';
import '../providers/quiz_providers.dart';
import '../providers/storage_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const routeName = '/stats';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    final questionsAsync = ref.watch(quizQuestionsProvider);
    final progressAsync  = ref.watch(playerProgressProvider);

    final prefs        = prefsAsync.valueOrNull;
    final userName     = prefs?.getString('userName') ?? 'Explorer';
    final avatarIndex  = prefs?.getInt('profileAvatar') ?? 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withOpacity(0.26)),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              Expanded(
                child: progressAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorState(message: e.toString()),
                  data: (PlayerProgress progress) {
                    return questionsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _ErrorState(message: e.toString()),
                      data: (List<QuizQuestion> questions) {
                        return Column(
                          children: [
                            _ProfileHeader(
                              userName: userName,
                              avatarIndex: avatarIndex,
                              progress: progress,
                              onStatsTap: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: _StatsContent(
                                userName: userName,
                                avatarIndex: avatarIndex,
                                progress: progress,
                                questions: questions,
                              ),
                            ),
                          ],
                        );
                      },
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
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.userName,
    required this.avatarIndex,
    required this.progress,
    required this.questions,
  });

  final String userName;
  final int avatarIndex;
  final PlayerProgress progress;
  final List<QuizQuestion> questions;

  static const Color _accent = Color(0xFFFFAF28);
  static const Color _cardColor = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    final totalQuizzes = questions.length;
    final completedQuizzes = progress.usedQuestionIds.length.clamp(
      0,
      totalQuizzes,
    );
    final remainingQuizzes = (totalQuizzes - completedQuizzes).clamp(
      0,
      totalQuizzes,
    );
    final completionRate = totalQuizzes == 0
        ? 0.0
        : completedQuizzes / totalQuizzes;

    final questionMap = {
      for (final question in questions) question.id: question,
    };

    final completedCategories = progress.usedQuestionIds
        .map((id) => questionMap[id]?.category?.trim())
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet();

    final totalCategories = questions
        .map((question) => question.category?.trim())
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    final averageXp = completedQuizzes == 0
        ? 0
        : (progress.xp / completedQuizzes).floor();

    final xpInfo = _XpInfo.fromProgress(progress);
    final achievements = _buildAchievements(
      completedQuizzes: completedQuizzes,
      completedCategories: completedCategories.length,
      xp: progress.xp,
      coins: progress.coins,
    );

    final stats = [
      _StatMetric(
        label: 'Quizzes Done',
        value: completedQuizzes.toString(),
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF00F5A0),
      ),
      _StatMetric(
        label: 'Remaining',
        value: remainingQuizzes.toString(),
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
        label: 'Coins Collected',
        value: progress.coins.toString(),
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
        label: 'Avg XP / Quiz',
        value: averageXp.toString(),
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF9DFF3B),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(
            userName: userName,
            avatarIndex: avatarIndex,
            progress: progress,
            xpInfo: xpInfo,
          ),
          const SizedBox(height: 28),
          Text(
            'Progress Overview',
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
                      label: 'Total quizzes',
                      value: totalQuizzes.toString(),
                      icon: Icons.playlist_add_check_rounded,
                    ),
                    _ProgressChip(
                      label: 'Completed',
                      value: completedQuizzes.toString(),
                      icon: Icons.bolt_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Key Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _StatsGrid(stats: stats),
          const SizedBox(height: 28),
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _AchievementsList(achievements: achievements),

          const SizedBox(height: 44),
        ],
      ),
    );
  }

  List<_AchievementData> _buildAchievements({
    required int completedQuizzes,
    required int completedCategories,
    required int xp,
    required int coins,
  }) {
    return [
      _AchievementData(
        title: 'First Spin',
        description: 'Complete your first quiz',
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFFFFF066),
        unlocked: completedQuizzes >= 1,
      ),
      _AchievementData(
        title: 'Quiz Explorer',
        description: 'Finish 5 quizzes',
        icon: Icons.travel_explore_rounded,
        accent: const Color(0xFF4ADE80),
        unlocked: completedQuizzes >= 5,
      ),
      _AchievementData(
        title: 'Category Collector',
        description: 'Master 3 categories',
        icon: Icons.grid_view_rounded,
        accent: const Color(0xFF00BBF9),
        unlocked: completedCategories >= 3,
      ),
      _AchievementData(
        title: 'Rising Star',
        description: 'Earn 250 XP overall',
        icon: Icons.stacked_line_chart_rounded,
        accent: const Color(0xFFFF6FB5),
        unlocked: xp >= 250,
      ),
      _AchievementData(
        title: 'Savings Booster',
        description: 'Collect 100 coins',
        icon: Icons.savings_rounded,
        accent: const Color(0xFFFFAF28),
        unlocked: coins >= 100,
      ),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.userName,
    required this.avatarIndex,
    required this.progress,
    required this.xpInfo,
  });

  final String userName;
  final int avatarIndex;
  final PlayerProgress progress;
  final _XpInfo xpInfo;

  static const Color _accent = Color(0xFFFFAF28);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFffbc2f), Color(0xFFfeb229)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFe58923), width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Level Progress',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      xpInfo.nextLevelXp != null
                          ? '${xpInfo.xpIntoLevel}/${xpInfo.nextLevelXp! - xpInfo.baseXp} XP'
                          : '${progress.xp} XP',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LinearProgressIndicator(
                    value: xpInfo.progressRatio,
                    minHeight: 12,
                    backgroundColor: Colors.black26,
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
                if (xpInfo.nextLevelXp != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${xpInfo.xpToNextLevel} XP to ${xpInfo.nextLevelLabel}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
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

class _XpInfo {
  const _XpInfo({
    required this.currentLevel,
    required this.baseXp,
    required this.nextLevelXp,
    required this.progressRatio,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.nextLevelLabel,
  });

  final PlayerLevel currentLevel;
  final int baseXp;
  final int? nextLevelXp;
  final double progressRatio;
  final int xpIntoLevel;
  final int? xpToNextLevel;
  final String nextLevelLabel;

  static _XpInfo fromProgress(PlayerProgress progress) {
    final level = progress.level;
    final base = _baseXpFor(level);
    final next = _nextXpFor(level);
    final xpIntoLevel = progress.xp - base;
    final xpSpan = next != null ? (next - base) : null;
    final ratio = xpSpan == null || xpSpan == 0
        ? 1.0
        : (xpIntoLevel / xpSpan).clamp(0.0, 1.0);

    final xpToNext = next != null ? (next - progress.xp).clamp(0, next) : null;

    return _XpInfo(
      currentLevel: level,
      baseXp: base,
      nextLevelXp: next,
      progressRatio: ratio,
      xpIntoLevel: xpIntoLevel,
      xpToNextLevel: xpToNext,
      nextLevelLabel: _labelForNext(level),
    );
  }

  static int _baseXpFor(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 0;
      case PlayerLevel.learner:
        return 50;
      case PlayerLevel.intermediate:
        return 150;
      case PlayerLevel.advanced:
        return 300;
      case PlayerLevel.pro:
        return 500;
    }
  }

  static int? _nextXpFor(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 50;
      case PlayerLevel.learner:
        return 150;
      case PlayerLevel.intermediate:
        return 300;
      case PlayerLevel.advanced:
        return 500;
      case PlayerLevel.pro:
        return null;
    }
  }

  static String _labelForNext(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 'Learner';
      case PlayerLevel.learner:
        return 'Intermediate';
      case PlayerLevel.intermediate:
        return 'Advanced';
      case PlayerLevel.advanced:
        return 'Pro';
      case PlayerLevel.pro:
        return 'Legend';
    }
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

const BoxDecoration _glassDecoration = BoxDecoration(
  color: _StatsContent._cardColor,
  borderRadius: BorderRadius.all(Radius.circular(24)),
  border: Border.fromBorderSide(BorderSide(color: Colors.white12)),
  boxShadow: [
    BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 1)),
  ],
);

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.avatarIndex,
    required this.progress,
    required this.onStatsTap,
  });

  final String userName;
  final int avatarIndex;
  final PlayerProgress progress;
  final VoidCallback onStatsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86 + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFe58923), width: 3),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFffbc2f), Color(0xFFfeb229)],
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
          IconButton.filled(
            iconSize: 18,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Color(0xFF232522), 
              foregroundColor: Colors.white,                    
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),                      
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: 6),
          
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
              Images.avatars[avatarIndex % Images.avatars.length],
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),

          // Username
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Text(
                      userName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 26,
                        height: 1,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 4
                          ..color = const Color(0xFFE2B400),
                      ),
                    ),
                    Text(
                      userName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1,
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

                const SizedBox(height: 2),

                Text(
                  progress.levelLabel,
                  style: const TextStyle(
                    color: Color(0xFF232522),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
                Image.asset(Images.coin, width: 24),
                const SizedBox(width: 20),
                Text(
                  progress.coins.toString(),
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