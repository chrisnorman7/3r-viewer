import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_key_form.dart';
import 'constants.dart';
import 'settings.dart';
import 'shift.dart';
import 'util.dart';
import 'volunteer.dart';
import 'volunteers_view.dart';

typedef CallbackType = void Function();


enum ShiftsToLoad {
  today,
  relevant,
}

class ShiftsView extends StatefulWidget {
  @override
  const ShiftsView(this.stl): super();

  final ShiftsToLoad stl;

  @override
  ShiftsViewState createState() => ShiftsViewState(stl);
}

class ShiftsViewState extends State<ShiftsView> {
  @override
  ShiftsViewState(this.stl): super();

  ShiftsToLoad stl;
  List<Shift> _shifts;
  String _error;
  bool refreshing;

  @override
  Widget build(BuildContext context) {
    refreshing ??= false;
    Widget child;
    final RaisedButton apiKeyButton = RaisedButton.icon(
      icon: Icon(Icons.settings),
      label: const Text('Enter API Key'),
      onPressed: () => setState(() {
        refreshing = false;
        pushRoute(context, ApiKeyForm());
      }),
    );
    final RaisedButton refreshButton = RaisedButton.icon(
      icon: Icon(Icons.refresh),
      label: const Text('Refresh'),
      onPressed: refreshing ? null : () => setState(() {
        refreshing = true;
        refresh();
      }),
    );
    final Map<String, CallbackType> menuItems = <String, CallbackType>{
      'Refresh': refreshButton.onPressed,
      'View All Volunteers': () => loadVolunteers(context),
      'Show ${stl == ShiftsToLoad.today ? "Relevant" : "Today\'s"} Shifts': () => setState(() {
        refreshing = true;
        if (stl == ShiftsToLoad.today) {
          stl = ShiftsToLoad.relevant;
        } else {
          stl = ShiftsToLoad.today;
        }
        refresh();
      }),
      '${settings.apiKey == null? "Set" : "Change"} API Key': apiKeyButton.onPressed,
    };
    if (settings.apiKey == null) {
      child = Column(
        children: <Widget>[
          const Text('You must enter an API key before 3 Rings can be accessed.'),
          apiKeyButton,
        ],
      );
    } else if (_shifts == null) {
      child = Column(
        children: <Widget>[
          const Text('Tap the refresh button to load shifts.'),
          refreshButton
        ]
      );
    } else if (_error != null) {
      child = Text(_error);
    } else {
      child = ListView.builder(
        itemCount: _shifts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Title(
              child: Text('Showing ${stl == ShiftsToLoad.today ? "Today\'s" : "Relevant"} shifts'),
              color: Colors.green,
            );
          }
          final Shift shift = _shifts[index - 1];
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
        leading: PopupMenuButton<CallbackType>(
          itemBuilder: (BuildContext context) {
            final List<PopupMenuItem<CallbackType>> mi = <PopupMenuItem<CallbackType>>[];
            menuItems.forEach(
              (String description, CallbackType cb) => mi.add(
                PopupMenuItem<CallbackType>(
                  child: Text(description),
                  value: cb,
                )
              )
            );
            return mi;
          },
          onSelected: refreshing ? null : (CallbackType cb) => setState(() {
            refreshing = true;
            cb();
          }),
          tooltip: 'Menu',
          icon: Icon(Icons.settings),
          enabled: !refreshing,
        ),
        title: const Text('3 Rings Viewer'),
        actions: <Widget>[
          refreshButton
        ],
      ),
      body: child,
    );
  }

  Future<void> refresh() async {
    final DateTime now = DateTime.now();
    String url = '$baseUrl/shift.json';
    if (stl == ShiftsToLoad.today) {
      final DateTime startDate = now.subtract(const Duration(days:1));
      final DateTime endDate = now.add(const Duration(days:1));
      url = '$url?start_date=${getTimestamp(startDate)}&end_date=${getTimestamp(endDate)}';
    }
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
          if ((shiftData['all_day'] as bool) == true || stl == ShiftsToLoad.today) {
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
          allDayShifts,
          previousShifts,
          currentShifts,
          nextShifts,
        ]) {
          shifts.sort(
            (Shift a, Shift b) => a.volunteers.length.compareTo(b.volunteers.length)
          );
          for (final Shift shift in shifts) {
            if (shift.volunteers.isNotEmpty) {
              _shifts.add(shift);
            }
          }
        }
      }
    }
    catch(e) {
      _error = e.toString();
    }
    finally {
      setState(() => refreshing = false);
    }
  }

  Future<void> loadVolunteers(BuildContext context) async {
    setState(() => refreshing = true);
    try {
      final http.Response r = await getJson('$baseUrl/directory.json');
      final List<Volunteer> volunteers = <Volunteer>[];
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
    }
    catch(e) {
      _error = e.toString();
    }
    finally {
      setState(() => refreshing = false);
    }
  }
}
