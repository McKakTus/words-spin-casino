import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppLinks {
  static String privacyPolicy =
      'https://www.privacypolicies.com/live/';

  static String terms =
      'https://app.websitepolicies.com/policies/view/';

  static Future<void> updateFromRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await remoteConfig.fetchAndActivate();

    final newPrivacy = remoteConfig.getString('privacyPolicy');

    if (newPrivacy.isNotEmpty) privacyPolicy = newPrivacy;
  }
}
