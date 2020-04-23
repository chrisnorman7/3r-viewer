import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'loading_page.dart';
import 'settings.dart';
import 'shifts_view.dart';

Future<void> main() async {
  runApp(
    MaterialApp(
      title: appTitle,
      home: LoadingPage(),
    )
  );
  final File apiKeyFile = File(apiKeyFilename);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (apiKeyFile.existsSync()) {
    final String apiKey = await apiKeyFile.readAsString();
    prefs.setString(apiKeyPreferenceName, apiKey);
  }
  settings.apiKey = prefs.getString(apiKeyPreferenceName);
  return runApp(
    MaterialApp(
      title: appTitle,
      home: const ShiftsView(ShiftsToLoad.today)
    )
  );
}
