import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../event.dart';
import '../refreshable_state.dart';
import '../util.dart';

class EventsTab extends StatefulWidget {
  @override
  EventsTabState createState() => EventsTabState();
}

class EventsTabState extends RefreshableState<EventsTab> {
  @override
  Widget getTitle() {
    return const Text('Events');
  }

  @override
  int itemsToShow() {
    return events == null ? null : events.length;
  }

  @override
  Widget getBodyWidget() {
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

  @override
  Future<void> mainRefresh() async {
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
}
