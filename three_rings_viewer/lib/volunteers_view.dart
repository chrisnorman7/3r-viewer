import 'package:flutter/material.dart';

import 'util.dart';
import 'volunteer.dart';
import 'volunteer_view.dart';

class VolunteersView extends StatelessWidget {
  @override
  const VolunteersView(this.volunteers) : super();

  final List<Volunteer> volunteers;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) =>
            GridView.count(
              crossAxisCount: orientation == Orientation.landscape ? 5 : 4,
              children: volunteers
                  .map((Volunteer volunteer) => GridTile(
                      header: Text(volunteer.name),
                      child: InkResponse(
                          child: volunteer.image,
                          onTap: () =>
                              pushRoute(context, VolunteerView(volunteer)))))
                  .toList(),
            ));
  }
}
