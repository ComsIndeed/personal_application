import 'package:flutter/material.dart';

class TabHeaderManager extends ChangeNotifier {
  String? _title;
  List<Widget>? _actions;
  Widget? _leading;
  int? _sourceTabIndex;

  String? get title => _title;
  List<Widget>? get actions => _actions;
  Widget? get leading => _leading;
  int? get sourceTabIndex => _sourceTabIndex;

  void update({
    String? title,
    List<Widget>? actions,
    Widget? leading,
    int? tabIndex,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _title = title;
      _actions = actions;
      _leading = leading;
      _sourceTabIndex = tabIndex;
      notifyListeners();
    });
  }
}
