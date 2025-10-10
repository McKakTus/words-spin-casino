import 'package:flutter/material.dart';

import '../helpers/image_paths.dart';
import '../helpers/xp_utils.dart';
import '../widgets/stroke_text.dart';
import '../models/player_progress.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.userName,
    required this.avatarIndex,
    required this.progress,
    required this.onStatsTap,
    this.showBackButton = true,
  });

  final String userName;
  final int avatarIndex;
  final PlayerProgress progress;
  final VoidCallback onStatsTap;
  final bool showBackButton;

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
          bottom: BorderSide(color: Color(0xFFD8D5EA), width: 5),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFACA2BF), Color(0xFF968AAB)],
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
          if (showBackButton)
            IconButton.filled(
              iconSize: 18,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF47356C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),

          if (showBackButton) const SizedBox(width: 6),

          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white38, width: 2),
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFD8D5EA), 
                  Color(0xFF978BAC), 
                ],
                center: Alignment.center,
                radius: 0.65, 
                stops: [0.47, 1.0],
              ),
              
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                Images.profiles[avatarIndex % Images.profiles.length],
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,  
              ),
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
                    StrokeText(
                      text: userName,
                      strokeColor: Color(0x33232522),
                      fontSize: 24,
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
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 12,
                                  fontFamily: 'Cookies',
                                ),
                              ),
                              Text(
                                '${progress.xp} XP',
                                style: const TextStyle(
                                  color: Color(0xCC232522),
                                  fontSize: 12,
                                  fontFamily: 'Cookies',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
              color: const Color(0xAA1F1039),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 2),
                Text(
                  progress.chips.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cookies',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(Images.coin, width: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
