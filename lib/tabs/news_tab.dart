import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../news.dart';
import '../news_view.dart';
import '../refreshable_state.dart';
import '../util.dart';
import '../volunteer.dart';

class NewsTab extends StatefulWidget {
  @override
  NewsTabState createState() => NewsTabState();
}

class NewsTabState extends RefreshableState<NewsTab> {
  @override
  Widget getTitle() {
    return const Text('News');
  }

  @override
  int itemsToShow() {
    return newsItems == null ? null : newsItems.length;
  }

  @override
  Widget getBodyWidget() {
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

  @override
  Future<void> mainRefresh() async {
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
}
