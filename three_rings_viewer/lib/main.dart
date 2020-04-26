import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'loading_page.dart';
import 'settings.dart';

import 'tabs/events_tab.dart';
import 'tabs/news_tab.dart';
import 'tabs/shifts_tab.dart';
import 'tabs/volunteers_tab.dart';

Future<void> main() async {
  runApp(
    MaterialApp(
      title: appTitle,
      home: LoadingPage(),
    )
  );
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  settings.apiKey = prefs.getString(apiKeyPreferenceName);
  tabs['Volunteers'] = const VolunteersTab('All Volunteers');
  tabs['News'] = NewsTab();
  tabs['Events'] = EventsTab();
  return runApp(
    MaterialApp(
      title: appTitle,
      home: ShiftsTab(),
    )
  );
}
