// removed unused import

import 'package:personal_application/core/models/command_data.dart';
import 'package:personal_application/core/models/message_part.dart';

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
