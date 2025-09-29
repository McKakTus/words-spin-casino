import 'dart:ui';
import 'package:flutter/material.dart';

import '../helpers/image_paths.dart';

import 'spin_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

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

        Scaffold(
          backgroundColor: Colors.transparent, 
          body: SafeArea(
            child: Column(
              children: [
                // Logo
                const Spacer(),
                
                // SizedBox(
                //   width: 240,
                //   child: Image.asset(Images.background),
                // ),
              
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      MenuButton(
                        text: 'Spin Wheel',
                        onPressed: () => Navigator.of(context).pushNamed(SpinScreen.routeName),
                      ),
                      const SizedBox(height: 20),
                      MenuButton(
                        text: 'Settings',
                        onPressed: () => Navigator.of(context).pushNamed(SettingsScreen.routeName),
                      ),
                      const SizedBox(height: 20),
                      MenuButton(
                        text: 'Stats',
                        onPressed: () => Navigator.of(context).pushNamed(StatsScreen.routeName),
                      ),
                      const SizedBox(height: 44),
                    ],
                  )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFe58923),
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.circular(34),
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFffaf28),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            textStyle: const TextStyle(
              fontFamily: 'MightySouly',
              fontSize: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }
}
