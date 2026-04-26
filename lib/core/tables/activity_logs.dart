import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:personal_application/core/models/activity_log.dart';

@UseRowClass(ActivityLog)
class ActivityLogs extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get activityType =>
      text().map(const EnumNameConverter<ActivityType>(ActivityType.values))();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();

  // Session link — null if no sprint was running
  TextColumn get sessionId => text().nullable()();
  IntColumn get elapsedSeconds => integer().nullable()();

  // taskCompletion + taskUpdate share taskId
  TextColumn get taskId => text().nullable()();

  // taskUpdate only
  TextColumn get updateContent => text().nullable()();

  // interruption only
  DateTimeColumn get pausedAt => dateTime().nullable()();
  DateTimeColumn get resumedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
