import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/storage_providers.dart';
import 'stats_screen.dart';
import 'word_screen.dart';

class SpinScreen extends ConsumerWidget {
  const SpinScreen({super.key});

  static const routeName = '/spin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref
        .watch(sharedPreferencesProvider)
        .maybeWhen(
          data: (prefs) => prefs.getString('userName') ?? 'Explorer',
          orElse: () => 'Explorer',
        );
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF040404), Color(0xFF181818)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Container(
              height: 76 + MediaQuery.paddingOf(context).top + 10,
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF6D736), width: 3),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF6D736), Color(0xFFE2B400)],
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
                children: [
                  const SizedBox(width: 14),
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: 
                      Image.asset('assets/images/avatar.jpg', 
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Username
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 24,
                            height: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Words learned 10',
                          style: const TextStyle(
                            color: Color(0xFF232522),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Coins pill (from provider)
                  Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232522),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/images/coin.png', width: 24),
                        const SizedBox(width: 20),
                        Text(
                          '24',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'n',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
        )
      ),
    );
  }
}