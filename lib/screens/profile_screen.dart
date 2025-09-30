import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../providers/storage_providers.dart';

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

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    final trimmedName = _nameController.text.trim();

    await prefs.setString('userName', trimmedName);
    await prefs.setInt('profileAvatar', _index);

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.of(context).pop(); 
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    const Color neonYellow = Color(0xFFffaf28);
    final paddingTop = MediaQuery.paddingOf(context).top + 20;

    return prefsAsync.when(
      data: (prefs) {
        if (!_loaded) {
          _nameController.text = prefs.getString('userName') ?? '';
          _index = prefs.getInt('profileAvatar') ?? 0;
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
                                    fontFamily: 'MightySouly',
                                    fontSize: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                onPressed: _isSaving ? null : _saveProfile,
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

                            const Spacer(),

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
                                    fontFamily: 'MightySouly',
                                    fontSize: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                onPressed: _isSaving ? null : _saveProfile,
                                child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text('Log Out'),
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
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final shouldReset =
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Text(
            'Are you sure you want to delete your account?',
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
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!shouldReset) return;

  await ref.read(playerProgressProvider.notifier).resetProgress();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Progress reset. Spin the wheel for a fresh start!'),
    ),
  );
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final shouldReset =
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Text(
            'Are you sure you want \n to log out?',
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
              child: const Text('Yes'),
            ),
          ],
        ),
      ) ??
      false;

  if (!shouldReset) return;

  await ref.read(playerProgressProvider.notifier).resetProgress();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Progress reset. Spin the wheel for a fresh start!'),
    ),
  );
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
