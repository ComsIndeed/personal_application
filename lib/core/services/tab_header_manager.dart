import 'package:flutter/material.dart';

class TabHeaderManager extends ChangeNotifier {
  String? _title;
  List<Widget>? _actions;

  String? get title => _title;
  List<Widget>? get actions => _actions;

  void update({String? title, List<Widget>? actions}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _title = title;
      _actions = actions;
      notifyListeners();
    });
  }
}
