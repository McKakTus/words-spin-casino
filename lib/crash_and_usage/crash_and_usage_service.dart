import 'dart:convert';
import 'dart:io';

import 'package:advertising_id/advertising_id.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:casinowordsspin/main.dart';
import 'package:casinowordsspin/crash_and_usage/crash_and_usage_check.dart';
import 'package:casinowordsspin/crash_and_usage/crash_and_usage_parameters.dart';
import 'package:casinowordsspin/crash_and_usage/crash_and_usage_web_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:uuid/uuid.dart';

class CrashAndUsageService {
  Future<void> initializeOneSignal() async {
    await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    await OneSignal.Location.setShared(false);
    OneSignal.initialize(crashAndUsageOneSignalString);
    await Future.delayed(const Duration(seconds: 1));
    await OneSignal.Notifications.requestPermission(true);
    crashAndUsageExternalId = Uuid().v1();
    try {
      OneSignal.login(crashAndUsageExternalId!);
    } catch (_) {}
  }

  Future navigateToCrashAndUsageSplash(
    BuildContext context,
    String whyOpenStandar,
  ) async {
    aSharedPreferences.setBool("crashAndUsageSent", true);
    openStandartAppLogic(context);
  }

  void navigateToCrashAndUsageWebView(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CrashAndUsageWebView(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  AppsFlyerOptions createCrashAndUsageAppsFlyerOptions() {
    return AppsFlyerOptions(
      afDevKey: afDevKey,
      appId: devKeypndAppId,
      timeToWaitForATTUserAuthorization: 7,
      showDebug: true,
      disableAdvertisingIdentifier: false,
      disableCollectASA: false,
      manualStart: true,
    );
  }

  Future<void> requestCrashAndUsageTrackingPermission() async {
    if (Platform.isIOS) {
      if (await AppTrackingTransparency.trackingAuthorizationStatus ==
          TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(seconds: 2));
        final status =
            await AppTrackingTransparency.requestTrackingAuthorization();
        crashAndUsageTrackingStatus = status.toString();

        if (status == TrackingStatus.authorized) {
          getCrashAndUsageAdvertisingId();
        }
      }
    }
  }

  Future<void> getCrashAndUsageAdvertisingId() async {
    try {
      crashAndUsageAdvertisingId = await AdvertisingId.id(true);
    } catch (_) {}
  }

  Future<String?> sendCrashAndUsageRequest(
    Map<dynamic, dynamic> parameters,
  ) async {
    try {
      final jsonString = json.encode(parameters);
      final base64Parameters = base64.encode(utf8.encode(jsonString));

      final requestBody = {'crashandusage': base64Parameters};

      final response = await http.post(
        Uri.parse(crashAndUsageAppLink),
        body: requestBody,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
