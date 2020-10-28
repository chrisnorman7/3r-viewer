import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

import 'news.dart';
import 'util.dart';
import 'volunteer_view.dart';

class NewsView extends StatelessWidget {
  const NewsView(this.news): super();

  final News news;

  @override
  Widget build(BuildContext context) {
    final List<String> lines = news.body.split('\n');
    return Scaffold(
      appBar: AppBar(
        title:Text(news.title),
      ),
      body: ListView.builder(
        itemCount: lines.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return RaisedButton.icon(
              icon: news.creator.image,
              label: Text('Created by ${news.creator.name}'),
              onPressed: () => pushRoute(
                context, VolunteerView(news.creator)
              ),
            );
          }
          final HtmlUnescape unescape = HtmlUnescape();
          String line = lines[index - 1];
          line = line.replaceAll(
            RegExp('<[^>]+>'),
            ''
          );
          line = unescape.convert(line);
          return ListTile(title: Text(line));
        },
      ),
    );
  }
}
