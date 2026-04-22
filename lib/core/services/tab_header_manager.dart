import 'package:flutter/material.dart';

class TabHeaderManager extends ChangeNotifier {
  String? _title;
  List<Widget>? _actions;
  Widget? _leading;
  VoidCallback? _onBack;
  int? _sourceTabIndex;

  String? get title => _title;
  List<Widget>? get actions => _actions;
  Widget? get leading => _leading;
  VoidCallback? get onBack => _onBack;
  int? get sourceTabIndex => _sourceTabIndex;

  void update({
    String? title,
    List<Widget>? actions,
    Widget? leading,
    VoidCallback? onBack,
    int? tabIndex,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _title = title;
      _actions = actions;
      _leading = leading;
      _onBack = onBack;
      _sourceTabIndex = tabIndex;
      notifyListeners();
    });
  }
}
