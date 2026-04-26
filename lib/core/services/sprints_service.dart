import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/activity_log.dart';
import '../models/common_note_item.dart';
import '../models/message/enums.dart';

class SprintsService {
  static final SprintsService _instance = SprintsService._internal();
  factory SprintsService() => _instance;
  SprintsService._internal();

  AppDatabase? _db;

  void setDatabase(AppDatabase db) {
    _db = db;
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Stream<List<CommonNoteItem>> watchTasks() {
    if (_db == null) return Stream.value([]);
    return (_db!.select(_db!.commonNoteItems)
          ..where((t) => t.category.equals(TabCategory.tasks.name))
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> promoteToTask(
    CommonNoteItem item, {
    required TaskType type,
    String? group,
    int? estTime,
    DateTime? dueDate,
  }) async {
    if (_db == null) return;

    await (_db!.update(
      _db!.commonNoteItems,
    )..where((t) => t.id.equals(item.id))).write(
      CommonNoteItemsCompanion(
        category: const Value(TabCategory.tasks),
        priority: Value(type),
        group: Value(group),
        estTime: Value(estTime),
        dueDate: Value(dueDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setCompletionStatus(String id, bool completed) async {
    if (_db == null) return;
    await (_db!.update(
      _db!.commonNoteItems,
    )..where((t) => t.id.equals(id))).write(
      CommonNoteItemsCompanion(
        completionStatus: Value(completed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  /// Creates a new sprint session and returns its generated id.
  Future<String> createSession(String folderKey) async {
    if (_db == null) return '';
    final companion = SprintSessionsCompanion(
      folderKey: Value(folderKey),
      startedAt: Value(DateTime.now()),
    );
    // insertReturning gives us back the full row so we can read the generated id.
    final row = await _db!.into(_db!.sprintSessions).insertReturning(companion);
    return row.id;
  }

  Future<void> endSession(String sessionId) async {
    if (_db == null) return;
    await (_db!.update(_db!.sprintSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(SprintSessionsCompanion(endedAt: Value(DateTime.now())));
  }

  // ─── Activity Logs ────────────────────────────────────────────────────────

  Stream<List<ActivityLog>> watchSessionLogs(String sessionId) {
    if (_db == null) return Stream.value([]);
    return (_db!.select(_db!.activityLogs)
          ..where((l) => l.sessionId.equals(sessionId))
          ..orderBy([(l) => OrderingTerm.asc(l.loggedAt)]))
        .watch();
  }

  Future<void> logTaskCompletion(
    String taskId, {
    String? sessionId,
    int? elapsedSeconds,
  }) async {
    if (_db == null) return;
    await _db!
        .into(_db!.activityLogs)
        .insert(
          ActivityLogsCompanion(
            activityType: const Value(ActivityType.taskCompletion),
            loggedAt: Value(DateTime.now()),
            taskId: Value(taskId),
            sessionId: Value(sessionId),
            elapsedSeconds: Value(elapsedSeconds),
          ),
        );
  }

  Future<void> logTaskUpdate(
    String taskId,
    String content, {
    String? sessionId,
    int? elapsedSeconds,
  }) async {
    if (_db == null) return;
    await _db!
        .into(_db!.activityLogs)
        .insert(
          ActivityLogsCompanion(
            activityType: const Value(ActivityType.taskUpdate),
            loggedAt: Value(DateTime.now()),
            taskId: Value(taskId),
            updateContent: Value(content),
            sessionId: Value(sessionId),
            elapsedSeconds: Value(elapsedSeconds),
          ),
        );
  }

  /// Inserts an open interruption log (resumedAt = null) and returns its id.
  Future<String> startInterruption({
    String? sessionId,
    int? elapsedSeconds,
  }) async {
    if (_db == null) return '';
    final row = await _db!
        .into(_db!.activityLogs)
        .insertReturning(
          ActivityLogsCompanion(
            activityType: const Value(ActivityType.interruption),
            loggedAt: Value(DateTime.now()),
            pausedAt: Value(DateTime.now()),
            sessionId: Value(sessionId),
            elapsedSeconds: Value(elapsedSeconds),
          ),
        );
    return row.id;
  }

  /// Closes an open interruption by writing its resumedAt timestamp.
  Future<void> endInterruption(String logId) async {
    if (_db == null) return;
    await (_db!.update(_db!.activityLogs)..where((l) => l.id.equals(logId)))
        .write(ActivityLogsCompanion(resumedAt: Value(DateTime.now())));
  }
}
