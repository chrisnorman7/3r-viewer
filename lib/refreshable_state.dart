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
    if (!refreshing &&
        (lastRefreshed == null ||
            now.difference(lastRefreshed).inMinutes >= 1)) {
      refresh();
    }
    Widget bodyWidget;
    if (settings.apiKey == null) {
      bodyWidget =
          const Text('You must first enter your API key from the main menu.');
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
            leading: getLeading(), title: getTitle(), actions: getActions()),
        body: bodyWidget);
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
    final IconButton refreshButton = IconButton(
      onPressed: refreshing == true ? null : refresh,
      icon: const Icon(Icons.refresh),
      tooltip: 'Refresh',
    );
    return <Widget>[refreshButton];
  }

  Widget getBodyWidget() {
    return const Text(
        'To change this text, override RefreshableState.getBodyWidget.');
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
    } catch (e) {
      error = e.toString();
    } finally {
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
