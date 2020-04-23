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
  VolunteerDetail(
    {
      this.name,
      this.type,
      this.value,
    }
  );

  final String name, value;
  DetailTypes type;
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
          if (detail.type == DetailTypes.email) {
            url = 'mailto:$url';
            icon = Icons.contact_mail;
          } else if (detail.type == DetailTypes.phone) {
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
        DetailTypes detailType;
        switch(entry['type'] as String) {
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
          detailValue = DateTime.parse(detailValue).toString();
        } else if (detailType == DetailTypes.boolean) {
          detailValue = detailValue == '1' ? 'Yes' : 'No';
        }
        if (<DetailTypes>[DetailTypes.date, DetailTypes.phone, DetailTypes.email, DetailTypes.text].contains(detailType)) {
          details.add(
            VolunteerDetail(
              name: detailName,
              type: detailType,
              value: detailValue,
            )
          );
        }
      }
    }
    setState(() {
    });
  }
}
