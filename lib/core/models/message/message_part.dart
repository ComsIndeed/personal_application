import 'package:personal_application/core/models/message/command_data.dart';

abstract class MessagePart {
  String get type;

  Map<String, dynamic> toJson();

  static MessagePart fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'text':
        return TextPart.fromJson(json);
      case 'reasoning':
        return ReasoningPart.fromJson(json);
      case 'asset':
        return AssetPart.fromJson(json);
      case 'command':
        return CommandPart.fromJson(json);
      default:
        throw Exception('Unknown message part type: $type');
    }
  }
}

class ReasoningPart extends MessagePart {
  @override
  String get type => 'reasoning';
  final String reasoning;

  ReasoningPart({required this.reasoning});

  @override
  Map<String, dynamic> toJson() => {'type': type, 'reasoning': reasoning};

  factory ReasoningPart.fromJson(Map<String, dynamic> json) =>
      ReasoningPart(reasoning: json['reasoning'] as String);
}

class TextPart extends MessagePart {
  @override
  String get type => 'text';
  final String text;

  TextPart({required this.text});

  @override
  Map<String, dynamic> toJson() => {'type': type, 'text': text};

  factory TextPart.fromJson(Map<String, dynamic> json) =>
      TextPart(text: json['text'] as String);
}

class AssetPart extends MessagePart {
  @override
  String get type => 'asset';
  final String assetId;

  AssetPart({required this.assetId});

  @override
  Map<String, dynamic> toJson() => {'type': type, 'assetId': assetId};

  factory AssetPart.fromJson(Map<String, dynamic> json) =>
      AssetPart(assetId: json['assetId'] as String);
}

class CommandPart extends MessagePart {
  @override
  String get type => 'command';
  final String name;
  final CommandData data;

  CommandPart({required this.name, required this.data});

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'data': data.toJson(),
  };

  factory CommandPart.fromJson(Map<String, dynamic> json) => CommandPart(
    name: json['name'] as String,
    data: CommandData.fromJson(json['data'] as Map<String, dynamic>),
  );
}
