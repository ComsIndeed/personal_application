// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetItem _$AssetItemFromJson(Map<String, dynamic> json) => AssetItem(
  id: json['id'] as String,
  userId: json['userId'] as String?,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deleted: json['deleted'] as bool,
  b2FileId: json['b2FileId'] as String?,
  b2FileName: json['b2FileName'] as String?,
  b2UpdatedAt: json['b2UpdatedAt'] == null
      ? null
      : DateTime.parse(json['b2UpdatedAt'] as String),
  displayName: json['displayName'] as String?,
  group: json['group'] as String?,
  mimeType: json['mimeType'] as String,
  size: (json['size'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$AssetItemToJson(AssetItem instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deleted': instance.deleted,
  'b2FileId': instance.b2FileId,
  'b2FileName': instance.b2FileName,
  'b2UpdatedAt': instance.b2UpdatedAt?.toIso8601String(),
  'displayName': instance.displayName,
  'group': instance.group,
  'mimeType': instance.mimeType,
  'size': instance.size,
  'createdAt': instance.createdAt.toIso8601String(),
};
