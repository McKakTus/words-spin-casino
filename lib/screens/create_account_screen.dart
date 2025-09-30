import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/storage_providers.dart';
import '../helpers/image_paths.dart';

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
  final _page = PageController(viewportFraction: 0.65);

  int _index = 0;
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
    await prefs.setInt('profileAvatar', _index);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    const Color neonYellow = Color(0xFFffaf28);

    final paddingTop = MediaQuery.paddingOf(context).top + 44;

    return prefsAsync.when(
      data: (prefs) {
        if (!_hasLoadedInitialName) {
          final existingName = prefs.getString('userName') ?? '';
          if (existingName.isNotEmpty && _nameController.text != existingName) {
            _nameController.text = existingName;
          }
          _hasLoadedInitialName = true;
        }
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
              body: Scaffold(
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
                                    'Welcome'.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 44,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 4
                                        ..color = const Color(0xFFE2B400),
                                    ),
                                  ),
                                  Text(
                                    'Welcome'.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 44,
                                      color: Color(0xFF000000),
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFF6D736),
                                          blurRadius: 2,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              const Text(
                                'Pick an avatar to represent you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 36),

                              SizedBox(
                                height: 270,
                                child: PageView.builder(
                                  controller: _page,
                                  onPageChanged: (i) =>
                                      setState(() => _index = i),
                                  itemCount: Images.avatars.length,
                                  itemBuilder: (_, i) => _AvatarCard(
                                    asset: Images.avatars[i],
                                    selected: _index == i,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

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
                                        fontSize: 24,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Display name',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFFB8B8B8),
                                        ),
                                        floatingLabelStyle: TextStyle(
                                          color: Colors.white,
                                        ),
                                        hintText: 'e.g. Word Wizard',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF6F6F6F),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF1C1C1C),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2E2E2E),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2E2E2E),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFF6D736),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your name to continue';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _isSaving ? const Color(0x669E9E9E) : const Color(0xFFe58923),
                                            width: 3,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(34),
                                      ),
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: neonYellow,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          textStyle: const TextStyle(
                                            fontFamily: 'MightySouly',
                                            fontSize: 24,
                                            letterSpacing: 0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              32,
                                            ),
                                          ),
                                        ),
                                        onPressed: _isSaving
                                            ? null
                                            : _saveAndContinue,
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                    ),
                                              )
                                            : const Text('Start Learning'),
                                      ),
                                    ),
                                  ],
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
            ),
          ],
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

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.asset, required this.selected});
  final String asset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(36)),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
