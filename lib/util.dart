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
    Uri.dataFromString(url),
    headers: getHeaders(),
  );
}

String errorFromCode(int code) {
  String errorString = 'Error: $code.';
  if (code == 403) {
    errorString +=
        ' The most likely cause of this error is an invalid API key. Try entering it again.';
  }
  return errorString;
}

String dateString(DateTime when, {bool includeTime = false}) {
  const List<String> monthNames = <String>[
    'January',
    'Febuary',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  String result = '${when.day} ${monthNames[when.month - 1]} ${when.year}';
  if (includeTime) {
    result += ' ${when.hour}:${when.minute}';
  }
  return result;
}
