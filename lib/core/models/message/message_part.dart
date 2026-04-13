// removed unused import

import 'package:personal_application/core/models/message/command_message_part.dart';
import 'package:personal_application/core/models/message/text_message_part.dart';

abstract class MessagePart {
  String get type;

  Map<String, dynamic> toJson();

  static MessagePart fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'text':
        return TextMessagePart.fromJson(json);
      case 'command':
        return CommandMessagePart.fromJson(json);
      default:
        throw Exception('Unknown message part type: $type');
    }
  }
}
