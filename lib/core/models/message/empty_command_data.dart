// removed unused import

import 'package:personal_application/core/models/message/command_data.dart';

class EmptyCommandData extends CommandData {
  @override
  Map<String, dynamic> toJson() => {};

  static EmptyCommandData fromJson(Map<String, dynamic> json) =>
      EmptyCommandData();
}
