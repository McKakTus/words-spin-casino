import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';

import '../providers/storage_providers.dart';

import 'create_account_screen.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final storedName = prefs.getString('userName');
    if (storedName == null || storedName.isEmpty) {
      Navigator.of(context).pushReplacementNamed(CreateAccountScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withAlpha(26)),
        ),

        Scaffold(backgroundColor: Colors.transparent, body: Container()),
      ],
    );
  }
}
