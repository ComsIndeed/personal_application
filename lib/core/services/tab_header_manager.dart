import 'package:flutter/material.dart';

class TabHeaderManager extends ChangeNotifier {
  String? _title;
  List<Widget>? _actions;
  Widget? _leading;

  String? get title => _title;
  List<Widget>? get actions => _actions;
  Widget? get leading => _leading;

  void update({String? title, List<Widget>? actions, Widget? leading}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _title = title;
      _actions = actions;
      _leading = leading;
      notifyListeners();
    });
  }
}
