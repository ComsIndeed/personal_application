import 'package:flutter/foundation.dart';

class ComposerHeightNotifier extends ChangeNotifier {
  double _height = 0;
  double get height => _height;

  void setHeight(double h) {
    if (_height != h) {
      _height = h;
      notifyListeners();
    }
  }
}
