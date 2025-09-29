import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/image_paths.dart';
import '../providers/storage_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

    Navigator.of(context).pop(); // вернуться назад после сохранения
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
          // прокрутить PageView к сохранённому аватару
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
              child: Container(color: Colors.black.withOpacity(0.26)),
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
                            // Заголовок
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Карусель аватаров
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

                            // Поле ввода имени
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
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

                            // Кнопка сохранить
                            Container(
                              width: double.infinity,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 56),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _isSaving
                                        ? const Color(0x669E9E9E)
                                        : const Color(0xFFe58923),
                                    width: 3,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(34),
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: neonYellow,
                                  foregroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
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
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
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
