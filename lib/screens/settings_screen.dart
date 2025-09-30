import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../helpers/link.dart';

import '../widgets/header.dart';

import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';

import 'profile_screen.dart';
import 'web_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

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
          child: Container(color: Colors.black.withAlpha(66)),
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

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 56),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MenuButton(
                            text: 'Profile',
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(ProfileScreen.routeName),
                          ),
                          const SizedBox(height: 20),
                          MenuButton(
                            text: 'Privacy Policy',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WebScreen(
                                  title: 'Privacy Policy',
                                  link: AppLinks.privacyPolicy,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          MenuButton(
                            text: 'Terms & Conditions',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WebScreen(
                                  title: 'Terms & Conditions',
                                  link: AppLinks.terms,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(message: e.toString()),
          ),
        ),
      ],
    );
  }
}

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const MenuButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(color: Color(0xFFe58923), width: 3),
          ),
          borderRadius: BorderRadius.circular(34),
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFffaf28),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            textStyle: const TextStyle(fontFamily: 'MightySouly', fontSize: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          onPressed: onTap,
          child: Text(text),
        ),
      ),
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
