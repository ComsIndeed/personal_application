// removed unused import

import 'package:personal_application/core/models/message_content.dart';
import 'package:personal_application/core/models/message_part.dart';

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
