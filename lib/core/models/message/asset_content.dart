// removed unused import

import 'package:personal_application/core/models/message/message_content.dart';

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
