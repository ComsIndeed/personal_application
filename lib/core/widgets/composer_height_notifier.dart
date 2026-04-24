import 'package:flutter/material.dart';

class AppComposerHeightNotifier extends ChangeNotifier {
  double _height = 0;
  double get height => _height;

  void setHeight(double value) {
    if (_height == value) return;
    _height = value;
    notifyListeners();
  }
}
