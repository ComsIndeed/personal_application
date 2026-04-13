import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../models/message_models.dart';
import 'conversation_items.dart';

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

class Messages extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get conversationId => text().references(Conversations, #id)();
  TextColumn get role => textEnum<MessageRole>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get parts => text().map(const MessagePartsConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
