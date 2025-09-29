import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';

import '../widgets/header.dart';

import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';

class WebScreen extends ConsumerWidget {
  final String title;
  final String link; 

  const WebScreen({
    super.key,
    required this.title,
    required this.link,
  });

  static const routeName = '/web';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    final progressAsync = ref.watch(playerProgressProvider);

    final prefs = prefsAsync.valueOrNull;
    final userName = prefs?.getString('userName') ?? 'Explorer';
    final avatarIndex = prefs?.getInt('profileAvatar') ?? 0;

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
          body: progressAsync.when(
            data: (progress) {
              return Column(
                children: [
                  ProfileHeader(
                    userName: userName,
                    avatarIndex: avatarIndex,
                    progress: progress,
                    onStatsTap: () => Navigator.of(context).pop(),
                  ),
                  
                  SizedBox(height: 32),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(message: e.toString()),
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