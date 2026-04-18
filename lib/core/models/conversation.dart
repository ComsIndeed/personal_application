import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncable/syncable.dart';
import 'package:drift/drift.dart' hide JsonKey;

import 'package:personal_application/core/database/app_database.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation extends Equatable implements Syncable {
  const Conversation({
    required this.id,
    this.userId,
    required this.updatedAt,
    required this.deleted,
    required this.createdAt,
    this.title,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  @override
  final String id;
  @override
  final String? userId;
  @override
  final DateTime updatedAt;
  @override
  final bool deleted;

  final DateTime createdAt;
  final String? title;

  @override
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  @override
  UpdateCompanion<Conversation> toCompanion() {
    return ConversationsCompanion(
      id: Value(id),
      userId: Value(userId),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      createdAt: Value(createdAt),
      title: Value(title),
    );
  }

  Conversation copyWith({
    String? id,
    String? userId,
    DateTime? updatedAt,
    bool? deleted,
    DateTime? createdAt,
    String? title,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
    );
  }

  @override
  List<Object?> get props => [id, userId, updatedAt, deleted, createdAt, title];

  @override
  bool get stringify => true;
}
