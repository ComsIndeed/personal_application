// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deleted: json['deleted'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  title: json['title'] as String?,
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted': instance.deleted,
      'created_at': instance.createdAt.toIso8601String(),
      'title': instance.title,
    };
