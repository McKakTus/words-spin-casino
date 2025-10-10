import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';
import '../widgets/primary_button.dart';
import '../widgets/stroke_text.dart';

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
  bool _isSaving = false;

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
                        const StrokeText(
                          text: 'LOG IN',
                          fontSize: 48,
                          strokeColor: Color(0xFFD8D5EA),
                          fillColor: Colors.white,
                          shadowColor: Color(0xFF46557B),
                          shadowBlurRadius: 2,
                          shadowOffset: Offset(0, 2),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter the display name you used\n when creating your profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 40,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Display name',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 18,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0x44FFFFFF),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      36,
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD8D5EA),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      36,
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD8D5EA),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      36,
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFFD8D5EA),
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Please enter your profile name.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              PrimaryButton(
                                label: 'Log In',
                                onPressed: _login,
                                busy: _isSaving,
                                enabled: !_isSaving,
                              ),
                            ],
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
