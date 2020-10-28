import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';
import 'util.dart';
import 'volunteer.dart';

enum DetailTypes {
  email,
  phone,
  date,
  string,
  text,
  select,
  boolean,
  unknown,
}

class VolunteerDetail {
  VolunteerDetail({
    this.name,
    this.type,
    this.value,
  });

  final String name, value;
  DetailTypes type;
}

class VolunteerView extends StatefulWidget {
  @override
  const VolunteerView(this._volunteer);

  final Volunteer _volunteer;

  @override
  VolunteerViewState createState() => VolunteerViewState(_volunteer);
}

class VolunteerViewState extends State<VolunteerView> {
  @override
  VolunteerViewState(this._volunteer);

  final Volunteer _volunteer;
  String _error;
  List<VolunteerDetail> _details;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_details == null) {
      child = const Text('Loading details...');
    } else if (_error != null) {
      child = Text(_error);
    } else {
      child = ListView.builder(
        itemCount: _details.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return FloatingActionButton(
              onPressed: () => launch('$baseUrl/directory/${_volunteer.id}'),
              child: const Icon(Icons.contacts),
              tooltip: 'Open in 3 Rings',
            );
          }
          final VolunteerDetail detail = _details[index - 1];
          String url = detail.value.replaceAll(' ', '');
          IconData icon;
          if (detail.type == DetailTypes.email) {
            url = 'mailto:$url';
            icon = Icons.contact_mail;
          } else if (detail.type == DetailTypes.phone) {
            url = 'tel:$url';
            icon = Icons.contact_phone;
          } else {
            url = null;
            icon = Icons.contacts;
          }
          return ListTile(
            leading: Icon(icon),
            title: Text(detail.name),
            subtitle: Text(detail.value),
            onTap: url == null ? null : () => launch(url),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_volunteer.name)),
      body: Center(child: child),
    );
  }

  Future<void> loadDetails() async {
    final String url =
        '$baseUrl/directory/${_volunteer.id}.toString()?format=json';
    final http.Response r = await getJson(url);
    _details = <VolunteerDetail>[];
    if (r.statusCode != 200) {
      _error = 'Error ${r.statusCode}.';
      if (r.statusCode == 404) {
        _error += '. Could not get "$url".';
      }
    } else {
      final dynamic volunteerData = jsonDecode(r.body)['volunteer'];
      final dynamic volunteerProperties = volunteerData['volunteer_properties'];
      for (final dynamic entry in volunteerProperties) {
        DetailTypes detailType;
        switch (entry['type'] as String) {
          case 'EmailProperty':
            detailType = DetailTypes.email;
            break;
          case 'TelProperty':
            detailType = DetailTypes.phone;
            break;
          case 'DateProperty':
            detailType = DetailTypes.date;
            break;
          case 'TextProperty':
            detailType = DetailTypes.text;
            break;
          case 'StringProperty':
            detailType = DetailTypes.string;
            break;
          case 'SelectProperty':
            detailType = DetailTypes.select;
            break;
          case 'BooleanProperty':
            detailType = DetailTypes.boolean;
            break;
          default:
            detailType = DetailTypes.unknown;
        }
        final String detailName = entry['name'] as String;
        String detailValue = entry['value'] as String;
        if (detailType == DetailTypes.date) {
          final DateTime date = DateTime.tryParse(detailValue);
          if (date == null) {
            detailValue = '!! Error while formatting DateTime !!';
          } else {
            detailValue = dateString(date);
          }
        } else if (detailType == DetailTypes.boolean) {
          detailValue = detailValue == '1' ? 'Yes' : 'No';
        }
        if (<DetailTypes>[
          DetailTypes.date,
          DetailTypes.phone,
          DetailTypes.email,
          DetailTypes.text
        ].contains(detailType)) {
          _details.add(VolunteerDetail(
            name: detailName,
            type: detailType,
            value: detailValue,
          ));
        }
      }
    }
    setState(() {});
  }
}
