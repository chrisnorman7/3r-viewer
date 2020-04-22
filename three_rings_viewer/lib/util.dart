import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'settings.dart';

String getTimestamp(DateTime when) {
  return '${when.year}-${when.month}-${when.day}';
}

void pushRoute(BuildContext context, Widget route) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) => route));
}

Map<String, String> getHeaders() {
  return <String, String>{
    'Authorization': 'APIKEY ${settings.apiKey}',
  };
}

Future<http.Response> getJson(String url) {
  return http.get(
    url,
    headers: getHeaders(),
  );
}
