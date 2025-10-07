import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';

import 'create_account_screen.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    final name = _nameController.text.trim();
    final profile = findProfileByName(prefs, name);

    if (profile == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No profile found for "$name".')));
      return;
    }

    await setActiveProfile(prefs, profile.id);
    ref.invalidate(sharedPreferencesProvider);
    ref.invalidate(playerProgressProvider);

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.paddingOf(context).top + 44;

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
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, paddingTop, 0, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 44,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 4
                                  ..color = const Color(0xFFE2B400),
                              ),
                            ),
                            const Text(
                              'Log In',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 44,
                                color: Color(0xFF000000),
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFF6D736),
                                    blurRadius: 2,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Display name',
                              labelStyle: const TextStyle(
                                color: Color(0xFFB8B8B8),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1C1C1C),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2E2E2E),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2E2E2E),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF6D736),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your profile name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 40,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: const Color(0xFFe58923),
                                width: 3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(34),
                          ),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFffaf28),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(
                                fontFamily: 'Cookies',
                                fontSize: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text('Log In'),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () =>
                                    Navigator.of(context).pushReplacementNamed(
                                      CreateAccountScreen.routeName,
                                    ),
                          child: const Text(
                            'Need a new profile? Create one',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
