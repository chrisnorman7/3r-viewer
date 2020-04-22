import 'package:flutter/material.dart';

import 'shift.dart';
import 'util.dart';
import 'volunteer.dart';
import 'volunteer_view.dart';

class ShiftView extends StatelessWidget {
  @override
  const ShiftView({this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shift.toString())),
      body: Center(
        child: ListView.builder(
          itemCount: shift.volunteers.length,
          itemBuilder: (BuildContext context, int index) {
            final Volunteer volunteer = shift.volunteers[index];
            return ListTile(
              title: Text(volunteer.name),
              onTap: () {
                Navigator.pop(context);
                pushRoute(context, VolunteerView(volunteer));
              }
            );
          },
        ),
      ),
    );
  }
}
