import 'package:flutter/material.dart';

import 'constants.dart';
import 'settings.dart';

class RefreshableState<T> extends State {
  bool refreshing = false;
  DateTime lastRefreshed;
  String error;

  @override
  Widget build(BuildContext context) {
    if (!refreshing && (lastRefreshed == null || lastRefreshed.difference(DateTime.now()).inHours >= 1)) {
      refresh();
    }
    Widget bodyWidget;
    if (settings.apiKey == null) {
      bodyWidget = const Text('First enter your API key from the menu, then tap the "Refresh" button.');
    } else if (refreshing) {
      bodyWidget = const Text('Loading...');
    } else if (itemsToShow() == null) {
      return const Text('Tap the "Refresh" button.');
    } else if (error != null) {
      bodyWidget = Text(error);
    } else if (itemsToShow() == 0) {
      bodyWidget = const Text('Nothing to show.');
    } else {
      bodyWidget = getBodyWidget();
    }
    refreshCallback = refresh;
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

  @mustCallSuper
  void beforeRefresh() {
    setState(() {
      error = null;
      refreshing = true;
    });
  }

  Future<void> mainRefresh() async {
    throw UnimplementedError;
  }

  Future<void> refresh() async {
    beforeRefresh();
    try {
      await mainRefresh();
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

  @mustCallSuper
  void afterRefresh() {
    lastRefreshed = DateTime.now();
    refreshing = false;
  }
}
