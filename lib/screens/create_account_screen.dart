import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../providers/player_progress_provider.dart';
import '../providers/storage_providers.dart';
import '../widgets/primary_button.dart';
import '../widgets/stroke_text.dart';

import 'home_screen.dart';
import 'login_screen.dart';

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

    final existing = findProfileByName(prefs, trimmedName);
    if (existing != null) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile "$trimmedName" already exists. Try logging in.')),
      );
      return;
    }

    final profile = ProfileData(
      id: generateProfileId(trimmedName),
      name: trimmedName,
      avatarIndex: _index,
    );

    await saveProfile(prefs, profile);
    ref.invalidate(sharedPreferencesProvider);
    ref.invalidate(playerProgressProvider);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    final paddingTop = MediaQuery.paddingOf(context).top + 44;

    return prefsAsync.when(
      data: (prefs) {
        if (!_hasLoadedInitialName) {
          _nameController.clear();
          _hasLoadedInitialName = true;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(Images.background, fit: BoxFit.cover),

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
                              const StrokeText(
                                text: 'WELCOME',
                                fontSize: 48,
                                strokeColor: Color(0xFFD8D5EA),
                                fillColor: Colors.white,
                                shadowColor: Color(0xFF46557B),
                                shadowBlurRadius: 2,
                                shadowOffset: Offset(0, 2),
                              ),

                              const SizedBox(height: 18),

                              const Text(
                                'Pick an avatar to represent you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 18,
                                ),
                              ),

                              const SizedBox(height: 36),

                              SizedBox(
                                height: 270,
                                child: PageView.builder(
                                  controller: _page,
                                  onPageChanged: (i) =>
                                      setState(() => _index = i),
                                  itemCount: Images.profiles.length,
                                  itemBuilder: (_, i) => _AvatarCard(
                                    asset: Images.profiles[i],
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
                                        hintText: 'e.g. Jony',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFFFFFFF),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0x44FFFFFF),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18,
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
                                          return 'Please enter your name to continue';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    PrimaryButton(
                                      label: 'Create profile',
                                      onPressed: _saveAndContinue,
                                      busy: _isSaving,
                                      enabled: !_isSaving,
                                    ),
                                  ],
                                ),
                              ),
                            
                              const Spacer(),
                              
                              TextButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => Navigator.of(context)
                                        .pushReplacementNamed(
                                          LoginScreen.routeName,
                                        ),
                                child: const Text(
                                  'Already have a profile? Log in',
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
        child: Material(
          color: const Color(0x34FFFFFF),            
          clipBehavior: Clip.antiAlias,             
          shape: RoundedRectangleBorder(             
            borderRadius: BorderRadius.circular(36),
            side: BorderSide(
              color: selected ? const Color(0xFFD8D5EA) : Colors.transparent,
              width: 4,
            ),
          ),
          child: AspectRatio(
            aspectRatio: 1,                         
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,   
            ),
          ),
        ),
      ),
    );
  }
}
