import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

import 'news.dart';
import 'util.dart';
import 'volunteer_view.dart';

class NewsView extends StatelessWidget {
  const NewsView(this._news) : super();

  final News _news;

  @override
  Widget build(BuildContext context) {
    final List<String> lines = _news.body.split('\n');
    return Scaffold(
      appBar: AppBar(
        title: Text(_news.title),
      ),
      body: ListView.builder(
        itemCount: lines.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return IconButton(
              icon: _news.creator.image,
              tooltip: 'Created by ${_news.creator.name}',
              onPressed: () => pushRoute(context, VolunteerView(_news.creator)),
            );
          }
          final HtmlUnescape unescape = HtmlUnescape();
          String line = lines[index - 1];
          line = line.replaceAll(RegExp('<[^>]+>'), '');
          line = unescape.convert(line);
          return ListTile(title: Text(line));
        },
      ),
    );
  }
}
