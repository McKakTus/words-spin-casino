import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/storage_providers.dart';
import 'home_screen.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  static const routeName = '/create-account';

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;
  bool _hasLoadedInitialName = false;

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

  Future<void> _saveAndContinue() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    final prefs = await ref.read(sharedPreferencesProvider.future);
    final trimmedName = _nameController.text.trim();
    await prefs.setString('userName', trimmedName);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    const Color neonYellow = Color(0xFFF6D736);
    const Color darkBackgroundTop = Color(0xFF080808);
    const Color darkBackgroundBottom = Color(0xFF1A1A1A);
    const Color cardColor = Color(0xFF111111);

    return prefsAsync.when(
      data: (prefs) {
        if (!_hasLoadedInitialName) {
          final existingName = prefs.getString('userName') ?? '';
          if (existingName.isNotEmpty && _nameController.text != existingName) {
            _nameController.text = existingName;
          }
          _hasLoadedInitialName = true;
        }
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [darkBackgroundTop, darkBackgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 24,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pick your name',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We\'ll use it for leaderboards and daily streaks.',
                              style: TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Display name',
                                labelStyle: const TextStyle(
                                  color: Color(0xFFB8B8B8),
                                ),
                                hintText: 'e.g. Word Wizard',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF6F6F6F),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1C1C1C),
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
                                  borderSide: BorderSide(color: neonYellow),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name to continue';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: neonYellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: const TextStyle(
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              letterSpacing: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveAndContinue,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text('Start Learning'),
                        ),
                      ),
                      const SizedBox(height: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong while loading your preferences.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
