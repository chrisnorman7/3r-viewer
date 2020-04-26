import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../menu_button.dart';
import '../refreshable_state.dart';
import '../shift.dart';
import '../util.dart';
import '../volunteer.dart';
import '../volunteers_view.dart';

enum ShiftsToLoad {
  today,
  relevant,
}

class ShiftsTab extends StatefulWidget {
  @override
  ShiftsTabState createState() => ShiftsTabState();
}

class ShiftsTabState extends RefreshableState<ShiftsTab> {
  ShiftsToLoad _stl;

  @override
  void initState() {
    _stl = ShiftsToLoad.relevant;
    super.initState();
  }

  @override
  Widget getLeading() {
    return MenuButton();
  }

  @override
  Widget getTitle() {
    return Text('${_stl == ShiftsToLoad.today ? "today\'s" : "Relevant"} shifts');
  }

  @override
  List<Widget> getActions() {
    final List<Widget> actions = super.getActions();
    final Map<String, ShiftsToLoad> menuItems = <String, ShiftsToLoad>{
      'Relevant': ShiftsToLoad.relevant,
      "Today's": ShiftsToLoad.today,
    };
    final PopupMenuButton<ShiftsToLoad> menuButton = PopupMenuButton<ShiftsToLoad>(
      itemBuilder: (BuildContext context) {
        final List<PopupMenuItem<ShiftsToLoad>> popupMenuItems = <PopupMenuItem<ShiftsToLoad>>[];
        menuItems.forEach(
          (String description, ShiftsToLoad value) => popupMenuItems.add(
            PopupMenuItem<ShiftsToLoad>(
              child: Text(description),
              value: value,
            )
          )
        );
        return popupMenuItems;
      },
      onSelected: refreshing == true ? null : (ShiftsToLoad value) {
        _stl = value;
        refresh();
      },
      tooltip: 'Change View',
      icon: Icon(Icons.settings),
      enabled: !(refreshing == true),
    );
    actions.insert(0, menuButton);
    return actions;
  }

  @override
  int itemsToShow() {
    return shifts == null ? null : shifts.length;
  }

  @override
  Widget getBodyWidget() {
    return ListView.builder(
      itemCount: shifts.length,
      itemBuilder: (BuildContext context, int index) {
        final Shift shift = shifts[index];
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

  @override
  Future<void> mainRefresh() async {
    final DateTime now = DateTime.now();
    String url = '$baseUrl/shift.json';
    final DateTime startDate = now.subtract(const Duration(days:1));
    url = '$url?start_date=${getTimestamp(startDate)}';
    final DateTime endDate = now.add(const Duration(days:1));
    url = '$url&end_date=${getTimestamp(endDate)}';
    http.Response r;
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
}
