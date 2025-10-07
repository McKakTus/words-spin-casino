import 'package:flutter/material.dart';

import '../helpers/image_paths.dart';
import '../helpers/xp_utils.dart';
import '../models/player_progress.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
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
              backgroundColor: const Color(0xFF232522),
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

          // Username + level
          Expanded(
            child: Builder(
              builder: (context) {
                final levelInfo = LevelProgressInfo.from(progress);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Text(
                          userName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                            color: const Color(0xFF000000),
                            shadows: [
                              Shadow(
                                color: const Color(0xFFF6D736),
                                blurRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                progress.levelLabel,
                                style: const TextStyle(
                                  color: Color(0xFF232522),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${progress.xp} XP',
                                style: const TextStyle(
                                  color: Color(0xFF232522),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: levelInfo.progressRatio,
                              minHeight: 6,
                              backgroundColor: const Color(0x33232522),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE6B400)),
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
                const SizedBox(width: 10),
                Text(
                  progress.chips.toString(),
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
