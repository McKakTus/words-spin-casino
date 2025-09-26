import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/create_account_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stats_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SpinToLearnApp()));
}

class SpinToLearnApp extends StatelessWidget {
  const SpinToLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BFA5),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Spin to Learn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Rubik',
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF111111),
        textTheme: const TextTheme(
          displaySmall: TextStyle(fontFamily: 'Rubik', letterSpacing: 1.1),
          headlineSmall: TextStyle(fontFamily: 'Rubik', letterSpacing: 1.05),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0x1AFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary.withAlpha(102)),
          ),
        ),
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        CreateAccountScreen.routeName: (_) => const CreateAccountScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        PracticeScreen.routeName: (_) => const PracticeScreen(),
        StatsScreen.routeName: (_) => const StatsScreen(),
      },
    );
  }
}
