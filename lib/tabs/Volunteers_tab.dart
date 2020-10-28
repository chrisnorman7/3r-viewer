import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../refreshable_state.dart';
import '../util.dart';
import '../volunteer.dart';
import '../volunteers_view.dart';

class VolunteersTab extends StatefulWidget {
  const VolunteersTab(this._title) : super();

  final String _title;

  @override
  VolunteersTabState createState() => VolunteersTabState(_title);
}

class VolunteersTabState extends RefreshableState<VolunteersTab> {
  @override
  VolunteersTabState(this._title) : super();

  final String _title;

  @override
  Widget getTitle() {
    return Text(_title);
  }

  @override
  int itemsToShow() {
    return volunteers == null ? null : volunteers.length;
  }

  @override
  Widget getBodyWidget() {
    return VolunteersView(volunteers.values.toList());
  }

  @override
  Future<void> mainRefresh() async {
    final http.Response r = await getJson('$baseUrl/directory.json');
    if (r.statusCode != 200) {
      throw errorFromCode(r.statusCode);
    }
    final dynamic volunteersData = jsonDecode(r.body)['volunteers'];
    volunteers = <int, Volunteer>{};
    for (final dynamic data in volunteersData) {
      final int volunteerId = data['id'] as int;
      final String volunteerName = data['name'] as String;
      volunteers[volunteerId] = Volunteer(
        id: volunteerId,
        name: volunteerName,
      );
    }
  }
}
