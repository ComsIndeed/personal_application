// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  userId: json['userId'] as String?,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deleted: json['deleted'] as bool,
  conversationId: json['conversationId'] as String,
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  parts: Message._partsFromJson(json['parts'] as List),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deleted': instance.deleted,
  'conversationId': instance.conversationId,
  'role': _$MessageRoleEnumMap[instance.role]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'parts': Message._partsToJson(instance.parts),
};

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.model: 'model',
  MessageRole.system: 'system',
  MessageRole.error: 'error',
};
