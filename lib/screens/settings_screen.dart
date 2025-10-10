import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../helpers/link.dart';

import '../widgets/header.dart';
import '../widgets/stroke_text.dart';
import '../widgets/primary_button.dart';

import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';

import 'profile_screen.dart';
import 'web_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final progressAsync = ref.watch(playerProgressProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: progressAsync.when(
            data: (progress) => profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(LoginScreen.routeName);
                  });
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    ProfileHeader(
                      userName: profile.name,
                      avatarIndex: profile.avatarIndex,
                      progress: progress,
                      onStatsTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 56),
                        child: Column(
                          children: [
                            const SizedBox(height: 46),
                            const StrokeText(
                              text: 'Settings',
                              fontSize: 44,
                              strokeColor: Color(0xFFD8D5EA),
                              fillColor: Colors.white,
                              shadowColor: Color(0xFF46557B),
                              shadowBlurRadius: 4,
                              shadowOffset: Offset(0, 3),
                            ),
                            const SizedBox(height: 40),
                            MenuButton(
                              text: 'Profile',
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(ProfileScreen.routeName),
                            ),
                            const SizedBox(height: 20),
                            MenuButton(
                              text: 'Privacy Policy',
                              onPressed: () => Navigator.of(context).push(
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
                              onPressed: () => Navigator.of(context).push(
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
  final VoidCallback onPressed;

  const MenuButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: text,
      onPressed: onPressed,
      uppercase: true,
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
