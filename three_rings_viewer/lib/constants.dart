import 'package:flutter/material.dart';

import 'shift.dart';
import 'volunteer.dart';

const String appTitle = 'Three Rings Viewer';
const String loadingText = 'Loading...';
const String noApiKeyText = 'You must first enter your API key.';
const String apiKeyPreferenceName = 'apiKey';
const String apiKeyFilename = 'api.key';
const String baseUrl = 'https://www.3r.org.uk';

List<Shift> shifts;
List<Volunteer> volunteers;

Map<String, Widget> tabs = <String, Widget>{};
