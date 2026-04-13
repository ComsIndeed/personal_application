// removed unused import

import 'package:personal_application/core/models/message/empty_command_data.dart';

abstract class CommandData {
  Map<String, dynamic> toJson();

  static CommandData fromJson(Map<String, dynamic> json) {
    // Current implementation has no specific command data types
    return EmptyCommandData.fromJson(json);
  }
}
