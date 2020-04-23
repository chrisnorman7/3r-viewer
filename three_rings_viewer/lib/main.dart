import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key_form.dart';
import 'constants.dart';
import 'loading_page.dart';
import 'settings.dart';
import 'shift.dart';
import 'util.dart';
import 'volunteer.dart';
import 'volunteers_view.dart';

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
      home: HomePage()
    )
  );
}

class HomePage extends StatefulWidget {
  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<HomePage> {
  List<Shift> _shifts;
  String _error;
  bool loadingVolunteers;

  @override
  Widget build(BuildContext context) {
    loadingVolunteers ??= false;
    Widget child;
    final FloatingActionButton apiKeyButton = FloatingActionButton(
      heroTag: 'API Key Button',
      child: Icon(Icons.settings),
      tooltip: 'Enter API Key',
      onPressed: () => pushRoute(context, ApiKeyForm()),
    );
    if (settings.apiKey == null) {
      child = ListView(
        children: <Widget>[
          const Text('You must enter an API key before we can communicate with 3 Rings.'),
          apiKeyButton,
        ],
      );
    } else if (_shifts == null) {
      child = const Text('Tap the refresh button to load shifts.');
    } else if (_error != null) {
      child = Text(_error);
    } else {
      child = ListView.builder(
        itemCount: _shifts.length,
        itemBuilder: (BuildContext context, int index) {
          final Shift shift = _shifts[index];
          return ListTile(
            title: Text(shift.name),
            subtitle: Text('(${shift.startString}-${shift.endString})'),
            onTap: () => pushRoute(context, VolunteersView(
              name: shift.name,
              volunteers: shift.volunteers
            ))
          );
        }
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('3 Rings Viewer'),
        actions: <Widget>[
          FloatingActionButton(
            heroTag: 'Volunteers Button',
            child: Icon(Icons.contacts),
            tooltip: 'Volunteers',
            onPressed: () {
              loadVolunteers(context);
            },
          ),
          FloatingActionButton(
            heroTag: 'Refresh Button',
            child: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refresh()
          ),
          apiKeyButton
        ]
      ),
      body: Center(
        child: child,
      )
    );
  }

  Future<void> refresh() async {
    final DateTime now = DateTime.now();
    final DateTime startDate = now.subtract(const Duration(days:1));
    final DateTime endDate = now.add(const Duration(days:1));
    final String url = '$baseUrl/shift.json?start_date=${getTimestamp(startDate)}&end_date=${getTimestamp(endDate)}';
    http.Response r;
    _shifts = <Shift>[];
    _error = null;
    try {
      r = await getJson(url);
      if (r.statusCode != 200) {
        _error = 'Error: ${r.statusCode}.';
        if (r.statusCode == 403) {
          _error += ' The most likely cause of this error is an invalid API key.';
        }
      } else {
        final Map<String, dynamic> data = jsonDecode(r.body) as Map<String, dynamic>;
        final List<dynamic> shifts = data['shifts'] as List<dynamic>;
        final List<Shift> currentShifts = <Shift>[];
        List<Shift> allDayShifts = <Shift>[], previousShifts = <Shift>[], nextShifts = <Shift>[];
        for (final dynamic shiftData in shifts) {
          final DateTime shiftStart = DateTime.tryParse(shiftData['start_datetime'] as String);
          final int duration = shiftData['duration'] as int;
          if (shiftStart == null || duration == null) {
            continue;
          }
          final DateTime shiftEnd = shiftStart.add(Duration(seconds: duration));
          final List<Volunteer> volunteers = <Volunteer>[];
          for (final dynamic volunteerShiftData in shiftData['volunteer_shifts']) {
            final dynamic volunteerData = volunteerShiftData['volunteer'];
            final int volunteerId = volunteerData['id'] as int;
            final String volunteerName = volunteerData['name'] as String;
            volunteers.add(
              Volunteer(
                id: volunteerId,
                name: volunteerName
              )
            );
          }
          final Shift shift = Shift(
            rotaId: shiftData['rota']['id'] as int,
            name: shiftData['rota']['name'] as String,
            start: shiftStart,
            end: shiftEnd,
            volunteers: volunteers,
          );
          if ((shiftData['all_day'] as bool) == true) {
            allDayShifts.add(shift);
          } else if (shiftStart.isBefore(now) && shift.end.isAfter(now)) {
            currentShifts.add(shift);
          } else if (shift.end.isBefore(now)) {
            previousShifts.add(shift);
          } else {
            nextShifts.add(shift);
          }
        }
        DateTime latestPreviousShift;
        for (final Shift shift in previousShifts) {
          if (latestPreviousShift == null || shift.start.isAfter(latestPreviousShift)) {
            latestPreviousShift = shift.start;
          }
        }
        previousShifts = previousShifts.where(
          (Shift entry) => entry.start.isAtSameMomentAs(latestPreviousShift)
        ).toList();
        DateTime earliestNextShift;
        for (final Shift shift in nextShifts) {
          if (earliestNextShift == null || shift.start.isBefore(earliestNextShift)) {
            earliestNextShift = shift.start;
          }
        }
        nextShifts = nextShifts.where(
          (Shift entry) => entry.start.isAtSameMomentAs(earliestNextShift)
        ).toList();
        allDayShifts = allDayShifts.where(
          (Shift entry) => entry.start.year == now.year && entry.start.month == now.month && entry.start.day == now.day
        ).toList();
        for (final List<Shift> shifts in <List<Shift>>[
          previousShifts,
          currentShifts,
          nextShifts,
          allDayShifts,
        ]) {
          for (final Shift shift in shifts) {
            if (shift.volunteers.isNotEmpty) {
              _shifts.add(shift);
            }
          }
        }
      }
    } catch(e) {
      _error = e.toString();
    }
    setState(() => null);
  }

  Future<void> loadVolunteers(BuildContext context) async {
    if (loadingVolunteers) {
      return;
    }
    loadingVolunteers = true;
    try {
      final http.Response r = await getJson('$baseUrl/directory.json');
      final List<Volunteer> volunteers = <Volunteer>[];
      loadingVolunteers = false;
      if (r.statusCode != 200) {
        pushRoute(
          context, VolunteersView(
            name: 'Loading volunteers failed: ${r.statusCode}',
            volunteers: volunteers,
          )
        );
        return;
      }
      final dynamic volunteersData = jsonDecode(r.body)['volunteers'];
      for (final dynamic data in volunteersData) {
        final int volunteerId = data['id'] as int;
        final String volunteerName = data['name'] as String;
        volunteers.add(
          Volunteer(
            id: volunteerId,
            name: volunteerName
          )
        );
      }
      pushRoute(
        context, VolunteersView(
          name: 'All Volunteers',
          volunteers: volunteers,
        )
      );
    } finally {
      loadingVolunteers = false;
    }
  }
}
