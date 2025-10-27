import 'package:casinowordsspin/main.dart';
import 'package:casinowordsspin/providers/storage_providers.dart';
import 'package:casinowordsspin/screens/create_account_screen.dart';
import 'package:casinowordsspin/screens/home_screen.dart';
import 'package:casinowordsspin/screens/login_screen.dart';
import 'package:flutter/material.dart';

String crashAndUsageOneSignalString = "b2a41e6d-4e74-47be-ac2d-c61c11c13624";
String afDevKey = "hNYE575rnPsXhWgTXMRzpB";
String devKeypndAppId = "6754245335";
String crashAndUsageAppLink = "https://casinowordsspin.games/crashandusage/";

void openStandartAppLogic(BuildContext context) async {
  final profile = readActiveProfile(aSharedPreferences);
  String next;
  if (profile != null) {
    next = HomeScreen.routeName;
  } else {
    final profiles = readAllProfiles(aSharedPreferences);
    next = profiles.isNotEmpty
        ? LoginScreen.routeName
        : CreateAccountScreen.routeName;
  }
  Navigator.of(context).pushReplacementNamed(next);
}
