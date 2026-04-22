// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common_note_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommonNoteItem _$CommonNoteItemFromJson(Map<String, dynamic> json) =>
    CommonNoteItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deleted: json['deleted'] as bool,
      category: $enumDecode(_$NoteCategoryEnumMap, json['category']),
      title: json['title'] as String?,
      textContent: json['text_content'] as String?,
      assetIds:
          (json['asset_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
      priority: $enumDecodeNullable(_$NotePriorityEnumMap, json['priority']),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CommonNoteItemToJson(CommonNoteItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted': instance.deleted,
      'category': _$NoteCategoryEnumMap[instance.category]!,
      'title': instance.title,
      'text_content': instance.textContent,
      'asset_ids': instance.assetIds,
      'tags': instance.tags,
      'created_at': instance.createdAt.toIso8601String(),
      'is_pinned': instance.isPinned,
      'priority': _$NotePriorityEnumMap[instance.priority],
      'due_date': instance.dueDate?.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$NoteCategoryEnumMap = {
  TabCategory.braindump: 'braindump',
  TabCategory.notes: 'notes',
  TabCategory.tasks: 'tasks',
};

const _$NotePriorityEnumMap = {
  TaskType.urgent: 'urgent',
  TaskType.approaching: 'approaching',
  TaskType.admin: 'admin',
  TaskType.fun: 'fun',
};
