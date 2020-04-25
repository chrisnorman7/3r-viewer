import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../settings.dart';
import '../util.dart';
import '../volunteer.dart';
import '../volunteers_view.dart';

class VolunteersTab extends StatefulWidget {
  const VolunteersTab(this.title): super();

  final String title;

  @override
  VolunteersTabState createState() => VolunteersTabState(title);
}

class VolunteersTabState extends State<VolunteersTab> {
  @override
  VolunteersTabState(this.title): super();

  String _error, title;
  bool _refreshing;

  @override
  void initState() {
    _refreshing = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final RaisedButton refreshButton = RaisedButton.icon(
      onPressed: _refreshing ? null : () => refresh(),
      icon: Icon(Icons.refresh),
      label: const Text('Refresh'),
    );
    if (!_refreshing && volunteers == null) {
      refresh();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[refreshButton],
      ),
      body: getBodyWidget()
    );
  }

  Widget getBodyWidget() {
    if (settings.apiKey == null) {
      return const Text(noApiKeyText);
    } else if (_refreshing) {
      return const Text(loadingText);
    } else if (_error != null) {
      return Text(_error);
    } else if (volunteers == null) {
      return const Center(
        child: Text('Press the refresh button to load volunteers.'),
      );
    } else if (volunteers.isEmpty) {
      return const Text('No volunteers to show.');
    } else {
      return VolunteersView(volunteers.values.toList());
    }
  }

  Future<void> refresh() async {
    setState(() {
      _error = null;
      _refreshing = true;
    });
    try {
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
