import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../event.dart';
import '../settings.dart';
import '../util.dart';

class EventsTab extends StatefulWidget {
  @override
  EventsTabState createState() => EventsTabState();
}

class EventsTabState extends State<EventsTab> {
  String _error;
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
    if (!_refreshing && events == null) {
      refresh();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
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
    } else if (events == null) {
      return const Center(
        child: Text('Press the refresh button to load events.'),
      );
    } else if (events.isEmpty) {
      return const Text('No events to show.');
    } else {
      return ListView.builder(
        itemCount: events.length,
        itemBuilder: (BuildContext context, int index) {
          final Event event = events[index];
          return ListTile(
            title: Text('${event.name} (${dateString(event.date)})'),
            subtitle: Text(event.description),
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
    try {
      final http.Response r = await getJson('$baseUrl/events.json');
      if (r.statusCode != 200) {
        throw errorFromCode(r.statusCode);
      }
      final List<dynamic> eventsData = jsonDecode(r.body)['events'] as List<dynamic>;
      events = <Event>[];
      for (final dynamic eventData in eventsData) {
        final String name = eventData['name'] as String;
        final String description = eventData['description'] as String;
        final String timestamp = eventData['date'] as String;
        DateTime date = DateTime.tryParse(timestamp);
        date = DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second);
        events.add(
          Event(
            name: name,
            description: description,
            date: date
          )
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
