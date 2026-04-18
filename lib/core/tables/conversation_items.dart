import 'package:drift/drift.dart';
import 'package:syncable/syncable.dart';
import 'package:uuid/uuid.dart';

import 'package:personal_application/core/models/conversation.dart';

@UseRowClass(Conversation)
class Conversations extends Table implements SyncableTable {
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
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
