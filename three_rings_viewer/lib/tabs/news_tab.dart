import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../news.dart';
import '../news_view.dart';
import '../settings.dart';
import '../util.dart';
import '../volunteer.dart';

class NewsTab extends StatefulWidget {
  @override
  NewsTabState createState() => NewsTabState();
}

class NewsTabState extends State<NewsTab> {
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
    if (!_refreshing && newsItems == null) {
      refresh();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
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
    } else if (newsItems == null) {
      return const Center(
        child: Text('Press the refresh button to load news.'),
      );
    } else if (newsItems.isEmpty) {
      return const Text('No news items to show.');
    } else {
      return ListView.builder(
        itemCount: newsItems.length,
        itemBuilder: (BuildContext context, int index) {
          final News newsItem = newsItems[index];
          return ListTile(
            title: Text(dateString(newsItem.date)),
            subtitle: Text(newsItem.title),
            onTap: () => pushRoute(
              context, NewsView(newsItem)
            )
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
      final http.Response r = await getJson('$baseUrl/news.json');
      if (r.statusCode != 200) {
        throw errorFromCode(r.statusCode);
      }
      final List<dynamic> newsItemsData= jsonDecode(r.body)['news_items'] as List<dynamic>;
      newsItems = <News>[];
      for (final dynamic newsData in newsItemsData) {
        final String title = newsData['title'] as String;
        final String body = newsData['body'] as String;
        final bool sticky = newsData['sticky'] as bool;
        final Map<String, dynamic> creator = newsData['creator'] as Map<String, dynamic>;
        final int volunteerId = creator['id'] as int;
        if (volunteers == null || !volunteers.containsKey(volunteerId)) {
          volunteers ??= <int, Volunteer>{};
          volunteers[volunteerId] = Volunteer(
            id: volunteerId,
            name: creator['name'] as String,
          );
        }
        final DateTime date = DateTime.tryParse(newsData['created_at'] as String) ?? DateTime.now();
        newsItems.add(
          News(
            title: title,
            body: body,
            sticky: sticky,
            creator: volunteers[volunteerId],
            date: date,
          )
        );
      }
      newsItems.sort(
        (News a, News b) {
          if (a.sticky) {
            if (b.sticky) {
              return 0;
            } else {
              return 1;
            }
          } else if (b.sticky) {
            return -1;
          } else {
            return 0;
          }
        }
      );
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
