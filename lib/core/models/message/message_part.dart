import 'package:personal_application/core/models/message/command_data.dart';
import 'package:personal_application/core/models/message/message_content.dart';

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

class TextMessagePart extends MessagePart {
  @override
  String get type => 'text';
  final List<MessageContent> contents;

  TextMessagePart({required this.contents});

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'contents': contents.map((e) => e.toJson()).toList(),
  };

  factory TextMessagePart.fromJson(Map<String, dynamic> json) =>
      TextMessagePart(
        contents: (json['contents'] as List<dynamic>)
            .map((e) => MessageContent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CommandMessagePart extends MessagePart {
  @override
  String get type => 'command';
  final String commandName;
  final CommandData commandData;

  CommandMessagePart({required this.commandName, required this.commandData});

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'commandName': commandName,
    'commandData': commandData.toJson(),
  };

  factory CommandMessagePart.fromJson(Map<String, dynamic> json) =>
      CommandMessagePart(
        commandName: json['commandName'] as String,
        commandData: CommandData.fromJson(
          json['commandData'] as Map<String, dynamic>,
        ),
      );
}
