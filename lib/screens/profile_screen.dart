import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../providers/storage_providers.dart';
import '../providers/player_progress_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/stroke_text.dart';

import 'create_account_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _ProfileScreenBody();
  }
}

class _ProfileScreenBody extends ConsumerStatefulWidget {
  const _ProfileScreenBody();

  @override
  ConsumerState<_ProfileScreenBody> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<_ProfileScreenBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _page = PageController(viewportFraction: 0.65);

  int _index = 0;
  bool _isSaving = false;
  bool _loaded = false;
  String? _profileId;
  bool _isRedirecting = false;

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

  Future<void> _saveProfile(ProfileData profile) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final trimmedName = _nameController.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    final existing = findProfileByName(prefs, trimmedName);
    if (existing != null && existing.id != profile.id) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Name "$trimmedName" already taken. Pick another.'),
          ),
        );
      }
      return;
    }

    final updated = ProfileData(
      id: profile.id,
      name: trimmedName,
      avatarIndex: _index,
    );

    await saveProfile(prefs, updated);
    ref.invalidate(sharedPreferencesProvider);
    ref.invalidate(activeProfileProvider);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);
    final paddingTop = MediaQuery.paddingOf(context).top + 44;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          _redirectAway();
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_loaded || _profileId != profile.id) {
          _profileId = profile.id;
          _nameController.text = profile.name;
          _index = profile.avatarIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_page.hasClients) {
              _page.jumpToPage(_index);
            }
          });
          _loaded = true;
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
                                text: 'PROFILE',
                                fontSize: 48,
                                strokeColor: Color(0xFFD8D5EA),
                                fillColor: Colors.white,
                                shadowColor: Color(0xFF46557B),
                                shadowBlurRadius: 2,
                                shadowOffset: Offset(0, 2),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Update your avatar and display name.',
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
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                        floatingLabelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        hintText: 'e.g. Jony',
                                        hintStyle: const TextStyle(
                                          color: Colors.white54,
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
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD8D5EA),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    PrimaryButton(
                                      label: 'Save profile',
                                      onPressed: _isSaving
                                          ? null
                                          : () {
                                              _saveProfile(profile);
                                            },
                                      busy: _isSaving,
                                      enabled: !_isSaving,
                                      textStyle: const TextStyle(
                                        fontSize: 22,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    PrimaryButton(
                                      label: 'Log out',
                                      onPressed: _isSaving
                                          ? null
                                          : () {
                                              _confirmLogout(context, ref);
                                            },
                                      enabled: !_isSaving,
                                      backgroundColor: const Color(0xFFFFAF28),
                                      borderColor: const Color(0xFFE58923),
                                      textStyle: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 22,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    PrimaryButton(
                                      label: 'Delete profile',
                                      onPressed: _isSaving
                                          ? null
                                          : () {
                                              _confirmDeleteAccount(context, ref);
                                            },
                                      enabled: !_isSaving,
                                      backgroundColor: const Color(0xFFE74C3C),
                                      borderColor: const Color(0xFFC0392B),
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
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
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );

  }

  void _redirectAway() {
    if (_isRedirecting) return;
    _isRedirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final profiles = readAllProfiles(prefs);
      if (!mounted) return;
      final route = profiles.isEmpty
          ? CreateAccountScreen.routeName
          : LoginScreen.routeName;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(route, (route) => false);
    });
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete profile?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'This will erase your name, avatar, and all progress. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6E6E),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  final prefs = await ref.read(sharedPreferencesProvider.future);
  final profile = await ref.read(activeProfileProvider.future);
  if (profile == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active profile to delete.')),
      );
    }
    return;
  }

  await deleteProfile(prefs, profile.id);
  ref.invalidate(sharedPreferencesProvider);
  ref.invalidate(activeProfileProvider);
  ref.invalidate(playerProgressProvider);

  final remaining = readAllProfiles(prefs);
  if (!context.mounted) return;

  final nextRoute =
      remaining.isEmpty ? CreateAccountScreen.routeName : LoginScreen.routeName;
  Navigator.of(context)
      .pushNamedAndRemoveUntil(nextRoute, (route) => false);
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'You will return to the onboarding screen and can sign in again later.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFAF28),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  final prefs = await ref.read(sharedPreferencesProvider.future);
  await clearActiveProfile(prefs);
  ref.invalidate(sharedPreferencesProvider);
  ref.invalidate(activeProfileProvider);
  ref.invalidate(playerProgressProvider);

  final remaining = readAllProfiles(prefs);
  if (!context.mounted) return;

  final nextRoute =
      remaining.isEmpty ? CreateAccountScreen.routeName : LoginScreen.routeName;
  Navigator.of(context)
      .pushNamedAndRemoveUntil(nextRoute, (route) => false);
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
