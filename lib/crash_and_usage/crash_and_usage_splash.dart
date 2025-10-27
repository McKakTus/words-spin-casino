import 'package:casinowordsspin/helpers/image_paths.dart';
import 'package:casinowordsspin/widgets/stroke_text.dart';
import 'package:flutter/material.dart';

class CrashAndUsageSplash extends StatefulWidget {
  const CrashAndUsageSplash({super.key});

  @override
  State<CrashAndUsageSplash> createState() => _CrashAndUsageSplashState();
}

class _CrashAndUsageSplashState extends State<CrashAndUsageSplash> {
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
                      Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      SizedBox(height: 20),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
