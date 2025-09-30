import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../helpers/image_paths.dart';

import '../widgets/header.dart';

import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';

import 'login_screen.dart';

class WebScreen extends ConsumerStatefulWidget {
  final String title;
  final String link;

  const WebScreen({super.key, required this.title, required this.link});

  static const routeName = '/web';

  @override
  ConsumerState<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends ConsumerState<WebScreen> {
  WebViewController? _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);
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

                    const SizedBox(height: 32),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              if (_ctrl != null)
                                WebViewWidget(controller: _ctrl!)
                              else
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),

                              if (_loading)
                                const Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
