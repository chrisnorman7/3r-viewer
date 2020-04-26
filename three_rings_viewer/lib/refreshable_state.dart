import 'package:flutter/material.dart';

import 'constants.dart';
import 'settings.dart';

class RefreshableState<T> extends State {
  bool refreshing = false;
  DateTime lastRefreshed;
  String error;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    if (lastRefreshed == null || lastRefreshed.difference(now).inHours >= 1 || itemsToShow() == null) {
      refresh();
    }
    Widget bodyWidget;
    if (settings.apiKey == null) {
      bodyWidget = Text(noApiKeyText);
    } else if (refreshing) {
      bodyWidget = Text(loadingText);
    } else if (error != null) {
      bodyWidget = Text(error);
    } else if (itemsToShow() == 0) {
      return const Text('Nothing to show.');
    } else {
      bodyWidget = getBodyWidget();
    }
    return Scaffold(
      appBar: AppBar(
        leading: getLeading(),
        title: getTitle(),
        actions: getActions()
      ),
      body: bodyWidget
    );
  }

  int itemsToShow() {
    return null;
  }

  Widget getLeading() {
    return null;
  }

  Widget getTitle() {
    return const Text('Untitled');
  }

  List<Widget> getActions() {
    final RaisedButton refreshButton = RaisedButton.icon(
      onPressed: refreshing == true ? null : refresh,
      icon: Icon(Icons.refresh),
      label: const Text('Refresh'),
    );
    return <Widget>[refreshButton];
  }

  Widget getBodyWidget() {
    return const Text('To change this text, override RefreshableState.getBodyWidget.');
  }

  void beforeRefresh() {
    setState(() {
      refreshing = true;
    });
  }

  Future<void> mainRefresh() async {
    throw UnimplementedError;
  }

  void refresh() {
    beforeRefresh();
    try {
      mainRefresh();
    }
    catch(e) {
      error = e.toString();
    }
    finally {
      if (mounted) {
        setState(() => afterRefresh());
      } else {
        afterRefresh();
      }
    }
  }

  void afterRefresh() {
    lastRefreshed = DateTime.now();
    refreshing = false;
  }
}
