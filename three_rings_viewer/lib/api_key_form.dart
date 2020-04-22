import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'settings.dart';

class ApiKeyForm extends StatefulWidget {
  const ApiKeyForm(this.callback);

  final void Function() callback;

  @override
  ApiKeyFormState createState() => ApiKeyFormState(callback);
}

class ApiKeyFormState extends State<ApiKeyForm> {
  ApiKeyFormState (this.callback);

  final TextEditingController apiTextController = TextEditingController(text: settings.apiKey);
  final void Function() callback;

  @override
  void dispose() {
    apiTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter your 3 rings API key'),
        actions: <Widget> [
          RaisedButton(
            onPressed: () async {
              final String apiKey = apiTextController.text;
              if (apiKey != settings.apiKey) {
                settings.apiKey = apiKey;
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setString(apiKeyPreferenceName, apiKey);
                callback();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: TextField(
          controller: apiTextController,
          decoration: const InputDecoration(
            labelText: 'API Key',
          ),
        ),
      )
    );
  }
}
