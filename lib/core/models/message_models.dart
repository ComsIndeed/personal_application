// removed unused import

enum MessageRole { user, model, system }

enum MediaType { image, video, audio, document, other }

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

abstract class MessageContent {
  String get type;
  Map<String, dynamic> toJson();

  static MessageContent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'text':
        return TextContent.fromJson(json);
      case 'asset':
        return AssetContent.fromJson(json);
      default:
        throw Exception('Unknown message content type: $type');
    }
  }
}

class TextContent extends MessageContent {
  @override
  String get type => 'text';
  final String text;

  TextContent({required this.text});

  @override
  Map<String, dynamic> toJson() => {'type': type, 'text': text};

  factory TextContent.fromJson(Map<String, dynamic> json) =>
      TextContent(text: json['text'] as String);
}

class AssetContent extends MessageContent {
  @override
  String get type => 'asset';
  final String assetId;

  AssetContent({required this.assetId});

  @override
  Map<String, dynamic> toJson() => {'type': type, 'assetId': assetId};

  factory AssetContent.fromJson(Map<String, dynamic> json) =>
      AssetContent(assetId: json['assetId'] as String);
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

abstract class CommandData {
  Map<String, dynamic> toJson();

  static CommandData fromJson(Map<String, dynamic> json) {
    // Current implementation has no specific command data types
    return EmptyCommandData.fromJson(json);
  }
}

class EmptyCommandData extends CommandData {
  @override
  Map<String, dynamic> toJson() => {};

  static EmptyCommandData fromJson(Map<String, dynamic> json) =>
      EmptyCommandData();
}
