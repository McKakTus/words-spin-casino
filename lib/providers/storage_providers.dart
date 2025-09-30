import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  final keepAliveLink = ref.keepAlive();
  ref.onDispose(keepAliveLink.close);
  return SharedPreferences.getInstance();
});

final activeProfileProvider = FutureProvider<ProfileData?>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final profile = readActiveProfile(prefs);
  if (profile != null) return profile;

  final legacyName = prefs.getString('userName');
  if (legacyName != null && legacyName.isNotEmpty) {
    final avatar = prefs.getInt('profileAvatar') ?? 0;
    final migrated = ProfileData(
      id: generateProfileId(legacyName),
      name: legacyName,
      avatarIndex: avatar,
    );
    await saveProfile(prefs, migrated);
    return migrated;
  }
  return null;
});

final profilesListProvider = FutureProvider<List<ProfileData>>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return readAllProfiles(prefs);
});

class ProfileData {
  ProfileData({
    required this.id,
    required this.name,
    required this.avatarIndex,
  });

  final String id;
  final String name;
  final int avatarIndex;
}

const _kProfileListKey = 'profileIds';
const _kProfileNamePrefix = 'profile_name_';
const _kProfileAvatarPrefix = 'profile_avatar_';
const _kActiveProfileKey = 'active_profile';

const xpKeyBase = 'playerXp';
const coinsKeyBase = 'playerCoins';
const usedQuestionsKeyBase = 'usedQuestions';

String composeProfileKey(String base, String profileId) => '${base}_$profileId';

String generateProfileId(String name) {
  final normalized = name.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );
  final slug = normalized.isEmpty ? 'player' : normalized;
  return '${slug}_${DateTime.now().millisecondsSinceEpoch}';
}

Future<void> saveProfile(SharedPreferences prefs, ProfileData profile) async {
  final ids = prefs.getStringList(_kProfileListKey) ?? <String>[];
  if (!ids.contains(profile.id)) {
    ids.add(profile.id);
    await prefs.setStringList(_kProfileListKey, ids);
  }
  await prefs.setString('$_kProfileNamePrefix${profile.id}', profile.name);
  await prefs.setInt(
    '$_kProfileAvatarPrefix${profile.id}',
    profile.avatarIndex,
  );
  await setActiveProfile(prefs, profile.id);
}

Future<void> deleteProfile(SharedPreferences prefs, String profileId) async {
  final ids = prefs.getStringList(_kProfileListKey) ?? <String>[];
  ids.remove(profileId);
  await prefs.setStringList(_kProfileListKey, ids);
  await prefs.remove('$_kProfileNamePrefix$profileId');
  await prefs.remove('$_kProfileAvatarPrefix$profileId');
  await prefs.remove(composeProfileKey(xpKeyBase, profileId));
  await prefs.remove(composeProfileKey(coinsKeyBase, profileId));
  await prefs.remove(composeProfileKey(usedQuestionsKeyBase, profileId));
  final active = prefs.getString(_kActiveProfileKey);
  if (active == profileId) {
    await clearActiveProfile(prefs);
  }
}

ProfileData? readProfile(SharedPreferences prefs, String profileId) {
  final name = prefs.getString('$_kProfileNamePrefix$profileId');
  if (name == null) return null;
  final avatar = prefs.getInt('$_kProfileAvatarPrefix$profileId') ?? 0;
  return ProfileData(
    id: profileId,
    name: name,
    avatarIndex: avatar,
  );
}

List<ProfileData> readAllProfiles(SharedPreferences prefs) {
  final ids = prefs.getStringList(_kProfileListKey) ?? <String>[];
  return ids
      .map((id) => readProfile(prefs, id))
      .whereType<ProfileData>()
      .toList(growable: false);
}

String? activeProfileId(SharedPreferences prefs) =>
    prefs.getString(_kActiveProfileKey);

ProfileData? readActiveProfile(SharedPreferences prefs) {
  final activeId = activeProfileId(prefs);
  if (activeId != null) {
    final profile = readProfile(prefs, activeId);
    if (profile != null) return profile;
  }
  return null;
}

ProfileData? findProfileByName(SharedPreferences prefs, String name) {
  final target = name.trim().toLowerCase();
  if (target.isEmpty) return null;
  final profiles = readAllProfiles(prefs);
  for (final profile in profiles) {
    if (profile.name.trim().toLowerCase() == target) {
      return profile;
    }
  }
  return null;
}

Future<void> setActiveProfile(SharedPreferences prefs, String profileId) async {
  await prefs.setString(_kActiveProfileKey, profileId);
  final profile = readProfile(prefs, profileId);
  if (profile != null) {
    await prefs.setString('userName', profile.name);
    await prefs.setInt('profileAvatar', profile.avatarIndex);
  }
}

Future<void> clearActiveProfile(SharedPreferences prefs) async {
  await prefs.remove(_kActiveProfileKey);
  await prefs.remove('userName');
  await prefs.remove('profileAvatar');
}
