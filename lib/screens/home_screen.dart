import 'dart:ui';
import 'package:flutter/material.dart';

import '../helpers/image_paths.dart';

import 'spin_screen.dart';
import 'stats_screen.dart';

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
                
                SizedBox(
                  width: 240,
                  child: Image.asset(Images.background),
                ),
              
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFffaf28),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                              fontFamily: 'MightySouly',
                              fontSize: 22,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(SpinScreen.routeName);
                          },
                          child: const Text('Spin Wheel'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFffaf28),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                              fontFamily: 'MightySouly',
                              fontSize: 22,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(SpinScreen.routeName);
                          },
                          child: const Text('Settings'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFffaf28),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                              fontFamily: 'MightySouly',
                              fontSize: 22,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(StatsScreen.routeName);
                          },
                          child: const Text('Stats'),
                        ),
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