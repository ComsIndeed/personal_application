import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:personal_application/core/models/sprint_session.dart';

@UseRowClass(SprintSession)
class SprintSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get folderKey => text()();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
