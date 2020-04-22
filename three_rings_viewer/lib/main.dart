import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key_form.dart';
import 'constants.dart';
import 'settings.dart';
import 'shift.dart';
import 'shift_view.dart';
import 'util.dart';
import 'volunteer.dart';

Future<void> main() async {
  final File apiKeyFile = File(apiKeyFilename);
  if (apiKeyFile.existsSync()) {
    final String apiKey = await apiKeyFile.readAsString();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(apiKeyPreferenceName, apiKey);
    settings.apiKey = prefs.getString(apiKeyPreferenceName);
  }
  return runApp(
    MaterialApp(
      title: '3R Viewer',
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

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_shifts == null) {
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
            onTap: () => pushRoute(context, ShiftView(shift: shift))
          );
        }
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('3 Rings Viewer'),
        actions: <Widget>[
          FloatingActionButton(
            child: Icon(Icons.settings),
            tooltip: 'Enter API Key',
            onPressed: () => pushRoute(context, ApiKeyForm(refresh))
          ),
          FloatingActionButton(
            heroTag: 'Refresh',
            child: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refresh()
          ),
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
    final http.Response r = await getJson(url);
    _shifts = <Shift>[];
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
    setState(() => null);
  }
}
