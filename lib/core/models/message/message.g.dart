// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deleted: json['deleted'] as bool,
  conversationId: json['conversation_id'] as String,
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  parts: Message._partsFromJson(json['parts'] as List),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted': instance.deleted,
  'conversation_id': instance.conversationId,
  'role': _$MessageRoleEnumMap[instance.role]!,
  'created_at': instance.createdAt.toIso8601String(),
  'parts': Message._partsToJson(instance.parts),
};

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.model: 'model',
  MessageRole.system: 'system',
  MessageRole.error: 'error',
};
