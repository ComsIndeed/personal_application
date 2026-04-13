// removed unused import

import 'package:personal_application/core/models/message/asset_content.dart';
import 'package:personal_application/core/models/message/text_content.dart';

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
