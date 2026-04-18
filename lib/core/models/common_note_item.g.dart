// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common_note_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommonNoteItem _$CommonNoteItemFromJson(Map<String, dynamic> json) =>
    CommonNoteItem(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deleted: json['deleted'] as bool,
      category: $enumDecode(_$NoteCategoryEnumMap, json['category']),
      title: json['title'] as String?,
      textContent: json['textContent'] as String?,
      assetIds:
          (json['assetIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      priority: $enumDecodeNullable(_$NotePriorityEnumMap, json['priority']),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CommonNoteItemToJson(CommonNoteItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deleted': instance.deleted,
      'category': _$NoteCategoryEnumMap[instance.category]!,
      'title': instance.title,
      'textContent': instance.textContent,
      'assetIds': instance.assetIds,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'isPinned': instance.isPinned,
      'priority': _$NotePriorityEnumMap[instance.priority],
      'dueDate': instance.dueDate?.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$NoteCategoryEnumMap = {
  NoteCategory.braindump: 'braindump',
  NoteCategory.notes: 'notes',
  NoteCategory.tasks: 'tasks',
};

const _$NotePriorityEnumMap = {
  NotePriority.urgent: 'urgent',
  NotePriority.approaching: 'approaching',
  NotePriority.admin: 'admin',
  NotePriority.fun: 'fun',
};
