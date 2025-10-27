import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:casinowordsspin/main.dart';
import 'package:casinowordsspin/crash_and_usage/crash_and_usage_service.dart';
import 'package:casinowordsspin/crash_and_usage/crash_and_usage_splash.dart';

import 'package:flutter/material.dart';

dynamic crashAndUsageConversionData;
String? crashAndUsageTrackingStatus;
String? crashAndUsageAdvertisingId;
String? crashAndUsageLink;

String? crashAndUsageAppsflyerId;
String? crashAndUsageExternalId;

class CrashAndUsageCheck extends StatefulWidget {
  static const routeName = '/start';

  const CrashAndUsageCheck({super.key});

  @override
  State<CrashAndUsageCheck> createState() => _CrashAndUsageCheckState();
}

class _CrashAndUsageCheckState extends State<CrashAndUsageCheck> {
  @override
  void initState() {
    super.initState();
    initAll();
  }

  initAll() async {
    await Future.delayed(Duration(milliseconds: 10));
    bool crashAndUsageSent =
        aSharedPreferences.getBool("crashAndUsageSent") ?? false;
    crashAndUsageLink = aSharedPreferences.getString("link");

    if (crashAndUsageLink != null &&
        crashAndUsageLink != "" &&
        !crashAndUsageSent) {
      CrashAndUsageService().navigateToCrashAndUsageWebView(context);
    } else {
      if (crashAndUsageSent) {
        CrashAndUsageService().navigateToCrashAndUsageSplash(context, "");
      } else {
        initializeMainPart();
      }
    }
  }

  void initializeMainPart() async {
    await CrashAndUsageService().requestCrashAndUsageTrackingPermission();
    await CrashAndUsageService().initializeOneSignal();
    await takeCrashAndUsageParams();
  }

  Future<void> createCrashAndUsageLink() async {
    Map<dynamic, dynamic> parameters = crashAndUsageConversionData;

    parameters.addAll({
      "track_status": crashAndUsageTrackingStatus,
      "crashandusage_id": crashAndUsageAdvertisingId,
      "appsflyer_id": crashAndUsageAppsflyerId,
      "external_id": crashAndUsageExternalId,
    });

    String? link = await CrashAndUsageService().sendCrashAndUsageRequest(
      parameters,
    );

    crashAndUsageLink = link;

    if (crashAndUsageLink == "" || crashAndUsageLink == null) {
      CrashAndUsageService().navigateToCrashAndUsageSplash(context, "");
    } else {
      aSharedPreferences.setString("link", crashAndUsageLink.toString());
      aSharedPreferences.setBool("success", true);
      CrashAndUsageService().navigateToCrashAndUsageWebView(context);
    }
  }

  Future<void> takeCrashAndUsageParams() async {
    final appsFlyerOptions = CrashAndUsageService()
        .createCrashAndUsageAppsFlyerOptions();
    AppsflyerSdk appsFlyerSdk = AppsflyerSdk(appsFlyerOptions);
    crashAndUsageAppsflyerId = await appsFlyerSdk.getAppsFlyerUID();
    await appsFlyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    appsFlyerSdk.onInstallConversionData((res) async {
      crashAndUsageConversionData = res;
      await createCrashAndUsageLink();
    });

    appsFlyerSdk.startSDK(
      onError: (errorCode, errorMessage) {
        CrashAndUsageService().navigateToCrashAndUsageSplash(context, "");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CrashAndUsageSplash();
  }
}
