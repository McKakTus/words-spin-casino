import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../providers/storage_providers.dart';
import '../providers/player_progress_provider.dart';

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

    const Color neonYellow = Color(0xFFffaf28);
    final paddingTop = MediaQuery.paddingOf(context).top + 20;

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
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(color: Colors.black.withAlpha(66)),
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
                                  'Edit Profile',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 36,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 4
                                      ..color = const Color(0xFFE2B400),
                                  ),
                                ),
                                Text(
                                  'Edit Profile',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 36,
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
                              child: TextFormField(
                                controller: _nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: 'Enter your name',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF6F6F6F),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1C1C1C),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2E2E2E),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2E2E2E),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF6D736),
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
                            ),
                            const SizedBox(height: 24),

                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 32,
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
                                  backgroundColor: neonYellow,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Cookies',
                                    fontSize: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _saveProfile(profile),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text('Save Profile'),
                              ),
                            ),

                            const SizedBox(height: 56),

                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 32,
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
                                  backgroundColor: Color(0xFFffaf28),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Cookies',
                                    fontSize: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _confirmLogout(context, ref),
                                child: const Text('Log Out'),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: const Color(0xFFe58923),
                                    width: 1,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(34),
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Cookies',
                                    fontSize: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () =>
                                        _confirmDeleteAccount(context, ref),
                                child: const Text('Delete Profile'),
                              ),
                            ),

                            const SizedBox(height: 44),
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
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(36)),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
