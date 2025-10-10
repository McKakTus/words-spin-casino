import 'dart:ui';
import 'package:flutter/material.dart';

import '../helpers/image_paths.dart';
import '../widgets/primary_button.dart';

import 'spin_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'boost_shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.home, fit: BoxFit.cover),

        Scaffold(
          backgroundColor: Colors.transparent, 
          body: SafeArea(
            child: Column(
              children: [
                // Logo
                const Spacer(),

                SizedBox(
                  width: 220,
                  child: Image.asset(Images.logo),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      MenuButton(
                        text: 'Spin Word Wheel',
                        onPressed: () =>
                            Navigator.of(context).pushNamed(SpinScreen.routeName),
                      ),
                      const SizedBox(height: 20),
                      MenuButton(
                        text: 'Settings',
                        onPressed: () => Navigator.of(context).pushNamed(SettingsScreen.routeName),
                      ),
                      const SizedBox(height: 20),
                      MenuButton(
                        text: 'Boost Shop',
                        onPressed: () => Navigator.of(context).pushNamed(BoostShopScreen.routeName),
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
    return PrimaryButton(
      label: text,
      onPressed: onPressed,
      uppercase: true,
    );
  }
}
