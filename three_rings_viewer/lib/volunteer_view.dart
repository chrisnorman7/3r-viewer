import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';
import 'util.dart';
import 'volunteer.dart';

class VolunteerDetail {
  VolunteerDetail(
    {
      this.name,
      this.type,
      this.value,
    }
  );

  final String name, type, value;
}

class VolunteerView extends StatefulWidget {
  @override
  const VolunteerView(this.volunteer);

  final Volunteer volunteer;

  @override
  VolunteerViewState createState() => VolunteerViewState(volunteer);
}

class VolunteerViewState extends State<VolunteerView> {
  @override
  VolunteerViewState(this.volunteer);

  final Volunteer volunteer;
  String _error;
  List<VolunteerDetail> details;

  @override
  void initState() {
    loadDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (details == null) {
      child = const Text('Loading details...');
    } else if (_error != null) {
      child = Text(_error);
    } else {
      child = ListView.builder(
        itemCount: details.length,
        itemBuilder: (BuildContext context, int index) {
          final VolunteerDetail detail = details[index];
          String url = detail.value.replaceAll(' ', '');
          IconData icon;
          if (detail.type == 'EmailProperty') {
            url = 'mailto:$url';
            icon = Icons.contact_mail;
          } else if (detail.type == 'TelProperty') {
            url = 'tel:$url';
            icon = Icons.contact_phone;
          } else {
            url = '$baseUrl/directory/${volunteer.id}';
            icon = Icons.contacts;
          }
          return ListTile(
            title: Text(detail.name),
            subtitle: Text(detail.value),
            trailing: Icon(icon),
            onTap: () => launch(url),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(volunteer.name)),
      body: Center(
        child: child
      ),
    );
  }

  Future<void> loadDetails() async {
    final String url = '$baseUrl/directory/${volunteer.id}.toString()?format=json';
    final http.Response r = await getJson(url);
    details = <VolunteerDetail>[];
    if (r.statusCode != 200) {
      _error = 'Error ${r.statusCode}.';
      if (r.statusCode == 404) {
        _error += '. Could not get "$url".';
      }
    } else {
      final dynamic volunteerData = jsonDecode(r.body)['volunteer'];
      final dynamic volunteerProperties = volunteerData['volunteer_properties'];
      for (final dynamic entry in volunteerProperties) {
        if (<String>['EmailProperty', 'TelProperty'].contains(entry['type'])) {
          details.add(
            VolunteerDetail(
              name: entry['name'] as String,
              type: entry['type'] as String,
              value: entry['value'] as String,
            )
          );
        }
      }
    }
    setState(() {
    });
  }
}
