import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../menu_button.dart';
import '../settings.dart';
import '../shift.dart';
import '../util.dart';
import '../volunteer.dart';
import '../volunteers_view.dart';

typedef CallbackType = void Function();

enum ShiftsToLoad {
  today,
  relevant,
}

class ShiftsTab extends StatefulWidget {
  @override
  ShiftsTabState createState() => ShiftsTabState();
}

class ShiftsTabState extends State<ShiftsTab> {
  ShiftsToLoad _stl;
  String _error;
  bool _refreshing;

  @override
  void initState() {
    _stl = ShiftsToLoad.relevant;
    _refreshing = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final RaisedButton refreshButton = RaisedButton.icon(
      icon: Icon(Icons.refresh),
      label: const Text('Refresh'),
      onPressed: _refreshing == null? null : () => setState(() {
        _refreshing = true;
        refresh();
      }),
    );
    final Map<String, CallbackType> menuItems = <String, CallbackType>{
      'Refresh': refreshButton.onPressed,
      'Show ${_stl == ShiftsToLoad.today ? "Only Relevant" : "Today\'s"} Shifts': () => setState(() {
        _refreshing = true;
        if (_stl == ShiftsToLoad.today) {
          _stl = ShiftsToLoad.relevant;
        } else {
          _stl = ShiftsToLoad.today;
        }
        refresh();
      }),
    };
    final PopupMenuButton<CallbackType> menuButton = PopupMenuButton<CallbackType>(
      itemBuilder: (BuildContext context) {
        final List<PopupMenuItem<CallbackType>> popupMenuItems = <PopupMenuItem<CallbackType>>[];
        menuItems.forEach(
          (String description, CallbackType cb) => popupMenuItems.add(
            PopupMenuItem<CallbackType>(
              child: Text(description),
              value: cb,
            )
          )
        );
        return popupMenuItems;
      },
      onSelected: _refreshing ? null : (CallbackType cb) => setState(() {
        _refreshing = true;
        cb();
      }),
      tooltip: 'Options',
      icon: Icon(Icons.settings),
      enabled: !_refreshing,
    );
    if (!_refreshing && shifts == null) {
      refresh();
    }
    return Scaffold(
      appBar: AppBar(
        leading: MenuButton(),
        title: const Text('Shifts'),
        actions: <Widget>[
          refreshButton,
          menuButton,
        ]
      ),
      body: getBodyWidget()
    );
  }

  Widget getBodyWidget() {
    if (settings.apiKey == null) {
      return const Text('You must first enter your API key.');
    } else if (_refreshing) {
      return const Text('Loading...');
    } else if (_error != null) {
      return Text(_error);
    } else if (shifts == null) {
      return const Center(
        child: Text('Tap the refresh button to load shifts.'),
      );
    } else {
      return ListView.builder(
        itemCount: shifts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Title(
              child: Text('Showing ${_stl == ShiftsToLoad.today ? "today\'s" : "Relevant"} shifts'),
              color: Colors.green,
            );
          }
          final Shift shift = shifts[index - 1];
          return ListTile(
            title: Text(shift.name),
            subtitle: Text('(${shift.startString}-${shift.endString})'),
            onTap: () => pushRoute(
              context, Scaffold(
                appBar: AppBar(title: Text(shift.toString())),
                body:VolunteersView(shift.volunteers),
              )
            )
          );
        }
      );
    }
  }

  Future<void> refresh() async {
    setState(() {
      _error = null;
      _refreshing = true;
    });
    final DateTime now = DateTime.now();
    String url = '$baseUrl/shift.json';
    final DateTime startDate = now.subtract(const Duration(days:1));
    url = '$url?start_date=${getTimestamp(startDate)}';
    final DateTime endDate = now.add(const Duration(days:1));
    url = '$url&end_date=${getTimestamp(endDate)}';
    http.Response r;
    try {
      r = await getJson(url);
      if (r.statusCode != 200) {
        throw errorFromCode(r.statusCode);
      }
      shifts = <Shift>[];
      final Map<String, dynamic> data = jsonDecode(r.body) as Map<String, dynamic>;
      final List<dynamic> shiftsData = data['shifts'] as List<dynamic>;
      final List<Shift> currentShifts = <Shift>[];
      List<Shift> allDayShifts = <Shift>[], previousShifts = <Shift>[], nextShifts = <Shift>[];
      for (final dynamic shiftData in shiftsData) {
        DateTime shiftStart = DateTime.tryParse(shiftData['start_datetime'] as String);
        final int duration = shiftData['duration'] as int;
        if (shiftStart == null || duration == null) {
          continue;
        }
        shiftStart = DateTime(shiftStart.year, shiftStart.month, shiftStart.day, shiftStart.hour, shiftStart.minute, shiftStart.second);
        final DateTime shiftEnd = shiftStart.add(Duration(seconds: duration));
        final List<Volunteer> volunteers = <Volunteer>[];
        for (final dynamic volunteerShiftData in shiftData['volunteer_shifts']) {
          final dynamic volunteerData = volunteerShiftData['volunteer'];
          final int volunteerId = volunteerData['id'] as int;
          final String volunteerName = volunteerData['name'] as String;
          volunteers.add(
            Volunteer(
              id: volunteerId,
              name: volunteerName,
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
        if ((shiftData['all_day'] as bool) == true || _stl == ShiftsToLoad.today) {
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
      for (final List<Shift> shiftsList in <List<Shift>>[
        allDayShifts,
        previousShifts,
        currentShifts,
        nextShifts,
      ]) {
        shiftsList.sort(
          (Shift a, Shift b) => a.volunteers.length.compareTo(b.volunteers.length)
        );
        for (final Shift shift in shiftsList) {
          if (shift.volunteers.isNotEmpty) {
            shifts.add(shift);
          }
        }
      }
    }
    catch(e) {
      _error = e.toString();
      rethrow;
    }
    finally {
      if (mounted) {
        setState(() => _refreshing = false);
      } else {
        _refreshing = false;
      }
    }
  }
}
