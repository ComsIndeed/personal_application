import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:syncable/syncable.dart';
import 'package:uuid/uuid.dart';

import 'package:personal_application/core/models/message/message_part.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message.dart';
import 'package:personal_application/core/tables/conversation_items.dart';

class MessagePartsConverter extends TypeConverter<List<MessagePart>, String> {
  const MessagePartsConverter();

  @override
  List<MessagePart> fromSql(String fromDb) {
    final list = json.decode(fromDb) as List<dynamic>;
    return list
        .map((item) => MessagePart.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  String toSql(List<MessagePart> value) {
    return json.encode(value.map((item) => item.toJson()).toList());
  }
}

@UseRowClass(Message)
class Messages extends Table implements SyncableTable {
  // --- Syncable required ---
  @override
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  @override
  TextColumn get userId => text().nullable()();
  @override
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  // --- Business columns ---
  TextColumn get conversationId => text().references(Conversations, #id)();
  TextColumn get role =>
      text().map(const EnumNameConverter<MessageRole>(MessageRole.values))();
  TextColumn get parts => text().map(const MessagePartsConverter())();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
