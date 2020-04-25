import 'package:flutter/material.dart';

class TabContainer {
  TabContainer(
    this.title,
    this.icon,
    this.widget,
    );

  String title;
  IconData icon;
  Widget widget;
}
