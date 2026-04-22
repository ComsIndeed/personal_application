import 'package:drift/drift.dart' hide JsonKey;
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncable/syncable.dart';

import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/message/enums.dart';

part 'common_note_item.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class CommonNoteItem extends Equatable implements Syncable {
  const CommonNoteItem({
    required this.id,
    this.userId,
    required this.updatedAt,
    required this.deleted,
    required this.category,
    this.title,
    this.textContent,
    this.assetIds = const [],
    this.tags = const [],
    required this.createdAt,
    this.isPinned = false,
    this.priority,
    this.group,
    this.estTime,
    this.completionStatus,
    this.timerSeconds,
    this.dueDate,
    this.metadata,
  });

  factory CommonNoteItem.fromJson(Map<String, dynamic> json) =>
      _$CommonNoteItemFromJson(json);

  // --- Syncable required ---
  @override
  final String id;
  @override
  final String? userId;
  @override
  final DateTime updatedAt;
  @override
  final bool deleted;

  // --- Core fields ---
  final TabCategory category;
  final String? title;
  final String? textContent;

  // --- References & Metadata ---
  final List<String> assetIds;
  final List<String> tags;

  // --- Additional helpful data ---
  final DateTime createdAt;
  final bool isPinned;
  final TaskType? priority;
  final String? group;
  final int? estTime;
  final bool? completionStatus;
  final int? timerSeconds;
  final DateTime? dueDate;
  final Map<String, dynamic>? metadata;

  @override
  Map<String, dynamic> toJson() => _$CommonNoteItemToJson(this);

  @override
  UpdateCompanion<CommonNoteItem> toCompanion() {
    return CommonNoteItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      category: Value(category),
      title: Value(title),
      textContent: Value(textContent),
      assetIds: Value(assetIds),
      tags: Value(tags),
      createdAt: Value(createdAt),
      isPinned: Value(isPinned),
      priority: Value(priority),
      group: Value(group),
      estTime: Value(estTime),
      completionStatus: Value(completionStatus),
      timerSeconds: Value(timerSeconds),
      dueDate: Value(dueDate),
      metadata: Value(metadata),
    );
  }

  CommonNoteItem copyWith({
    String? id,
    String? userId,
    DateTime? updatedAt,
    bool? deleted,
    TabCategory? category,
    String? title,
    String? textContent,
    List<String>? assetIds,
    List<String>? tags,
    DateTime? createdAt,
    bool? isPinned,
    TaskType? priority,
    String? group,
    int? estTime,
    bool? completionStatus,
    int? timerSeconds,
    DateTime? dueDate,
    Map<String, dynamic>? metadata,
  }) {
    return CommonNoteItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      category: category ?? this.category,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      assetIds: assetIds ?? this.assetIds,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      priority: priority ?? this.priority,
      group: group ?? this.group,
      estTime: estTime ?? this.estTime,
      completionStatus: completionStatus ?? this.completionStatus,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      dueDate: dueDate ?? this.dueDate,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    updatedAt,
    deleted,
    category,
    title,
    textContent,
    assetIds,
    tags,
    createdAt,
    isPinned,
    priority,
    group,
    estTime,
    completionStatus,
    timerSeconds,
    dueDate,
    metadata,
  ];

  @override
  bool get stringify => true;
}
