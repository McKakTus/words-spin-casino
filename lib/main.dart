import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/splash_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/spin_screen.dart';
import 'screens/boost_shop_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: WordsSpinCasinoApp()));
}

class WordsSpinCasinoApp extends StatelessWidget {
  const WordsSpinCasinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xAA1F1039),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Casino Words Spin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cookies',
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF111111),
        textTheme: const TextTheme(
          displaySmall: TextStyle(fontFamily: 'Cookies', letterSpacing: 1.1),
          headlineSmall: TextStyle(fontFamily: 'Cookies', letterSpacing: 1.05),
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
        LoginScreen.routeName: (_) => const LoginScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        SpinScreen.routeName: (_) => const SpinScreen(),
        StatsScreen.routeName: (_) => const StatsScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        BoostShopScreen.routeName: (_) => const BoostShopScreen(),
      },
    );
  }
}