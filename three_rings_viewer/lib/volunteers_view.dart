import 'package:flutter/material.dart';

import 'constants.dart';
import 'util.dart';
import 'volunteer.dart';
import 'volunteer_view.dart';

class VolunteersView extends StatelessWidget {
  @override
  const VolunteersView(
    {
      this.name,
      this.volunteers
    }
  );

  final String name;
  final List<Volunteer> volunteers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: ListView.builder(
          itemCount: volunteers.length,
          itemBuilder: (BuildContext context, int index) {
            final Volunteer volunteer = volunteers[index];
            return ListTile(
              title: Text(volunteer.name),
              subtitle: Image.network(
                '$baseUrl/directory/${volunteer.id}/photos/thumb.jpg',
                headers: getHeaders(),
              ),
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
