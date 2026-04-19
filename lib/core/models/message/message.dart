import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncable/syncable.dart';
import 'package:drift/drift.dart' hide JsonKey;

import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';

part 'message.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Message extends Equatable implements Syncable {
  const Message({
    required this.id,
    this.userId,
    required this.updatedAt,
    required this.deleted,
    required this.conversationId,
    required this.role,
    required this.parts,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  @override
  final String id;
  @override
  final String? userId;
  @override
  final DateTime updatedAt;
  @override
  final bool deleted;

  final String conversationId;
  final MessageRole role;
  final DateTime createdAt;
  @JsonKey(fromJson: _partsFromJson, toJson: _partsToJson)
  final List<MessagePart> parts;

  static List<MessagePart> _partsFromJson(List<dynamic> json) =>
      json.map((e) => MessagePart.fromJson(e as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> _partsToJson(List<MessagePart> parts) =>
      parts.map((e) => e.toJson()).toList();

  @override
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  UpdateCompanion<Message> toCompanion() {
    return MessagesCompanion(
      id: Value(id),
      userId: Value(userId),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      conversationId: Value(conversationId),
      role: Value(role),
      parts: Value(parts),
      createdAt: Value(createdAt),
    );
  }

  Message copyWith({
    String? id,
    String? userId,
    DateTime? updatedAt,
    bool? deleted,
    String? conversationId,
    MessageRole? role,
    List<MessagePart>? parts,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      parts: parts ?? this.parts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    updatedAt,
    deleted,
    conversationId,
    role,
    parts,
    createdAt,
  ];

  @override
  bool get stringify => true;
}
