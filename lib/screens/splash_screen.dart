import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../widgets/stroke_text.dart';
import '../widgets/primary_button.dart';

import '../providers/storage_providers.dart';

import 'create_account_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isResolving = true;
  String? _targetRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveNextRoute();
    });
  }

  Future<void> _resolveNextRoute() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (!mounted) return;

    final profile = readActiveProfile(prefs);
    String next;
    if (profile != null) {
      next = HomeScreen.routeName;
    } else {
      final profiles = readAllProfiles(prefs);
      next = profiles.isNotEmpty
          ? LoginScreen.routeName
          : CreateAccountScreen.routeName;
    }

    setState(() {
      _targetRoute = next;
      _isResolving = false;
    });
  }

  void _goNext() {
    final route = _targetRoute;
    if (route == null || !mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.splah, fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.25)),

        Scaffold(
          backgroundColor: Colors.transparent, 
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 240,
                      child: Image.asset(Images.logo),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StrokeText(
                        text: 'WELCOME TO',
                        fontSize: 28,
                        strokeColor: Color(0xFFD8D5EA),
                        fillColor: Colors.white,
                        shadowColor: Color(0xFF46557B),
                        shadowBlurRadius: 2,
                        height: 1.2,
                      ),
                      const SizedBox(height: 4),
                      const StrokeText(
                        text: 'CASINO WORDS SPIN',
                        fontSize: 34,
                        strokeColor: Color(0xFFD8D5EA),
                        fillColor: Colors.white,
                        shadowColor: Color(0xFF46557B),
                        shadowBlurRadius: 2,
                        height: 1.2,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Spin the wheel, solve the word, earn the rewards',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: 'Get Started',
                        enabled: !_isResolving && _targetRoute != null,
                        busy: _isResolving,
                        onPressed: _targetRoute != null ? _goNext : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ),
      ],
    );
  }
}
