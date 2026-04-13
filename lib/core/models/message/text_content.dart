// removed unused import

import 'package:personal_application/core/models/message/message_content.dart';

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
