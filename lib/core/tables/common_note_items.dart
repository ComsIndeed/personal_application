import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:syncable/syncable.dart';
import 'package:uuid/uuid.dart';

import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/common_note_item.dart';

class ListConverter extends TypeConverter<List<String>, String> {
  const ListConverter();
  @override
  List<String> fromSql(String fromDb) {
    return (json.decode(fromDb) as List).map((e) => e as String).toList();
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

class MapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const MapConverter();
  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return json.decode(fromDb) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}

@UseRowClass(CommonNoteItem)
class CommonNoteItems extends Table implements SyncableTable {
  // --- Syncable required ---
  @override
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  @override
  TextColumn get userId => text().nullable()();
  @override
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  // --- Core fields ---
  IntColumn get category => intEnum<NoteCategory>()();
  TextColumn get title => text().nullable()();
  TextColumn get textContent => text().nullable()();

  // --- References & Metadata ---
  TextColumn get assetIds =>
      text().map(const ListConverter()).withDefault(const Constant('[]'))();
  TextColumn get tags =>
      text().map(const ListConverter()).withDefault(const Constant('[]'))();

  // --- Additional helpful data ---
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get priority => intEnum<NotePriority>().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get metadata => text().map(const MapConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
