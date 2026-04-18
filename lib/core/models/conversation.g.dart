// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: json['id'] as String,
  userId: json['userId'] as String?,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  deleted: json['deleted'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  title: json['title'] as String?,
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deleted': instance.deleted,
      'createdAt': instance.createdAt.toIso8601String(),
      'title': instance.title,
    };
