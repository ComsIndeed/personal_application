// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetItem _$AssetItemFromJson(Map<String, dynamic> json) => AssetItem(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deleted: json['deleted'] as bool,
  b2FileId: json['b2_file_id'] as String?,
  b2FileName: json['b2_file_name'] as String?,
  b2UpdatedAt: json['b2_updated_at'] == null
      ? null
      : DateTime.parse(json['b2_updated_at'] as String),
  displayName: json['display_name'] as String?,
  group: json['group'] as String?,
  mimeType: json['mime_type'] as String,
  size: (json['size'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AssetItemToJson(AssetItem instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted': instance.deleted,
  'b2_file_id': instance.b2FileId,
  'b2_file_name': instance.b2FileName,
  'b2_updated_at': instance.b2UpdatedAt?.toIso8601String(),
  'display_name': instance.displayName,
  'group': instance.group,
  'mime_type': instance.mimeType,
  'size': instance.size,
  'created_at': instance.createdAt.toIso8601String(),
};
