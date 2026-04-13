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
