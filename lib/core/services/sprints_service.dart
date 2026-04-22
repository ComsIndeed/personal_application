import 'package:drift/drift.dart';
import '../database/app_database.dart';
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

  Future<void> updateTimer(String id, int seconds) async {
    if (_db == null) return;
    await (_db!.update(
      _db!.commonNoteItems,
    )..where((t) => t.id.equals(id))).write(
      CommonNoteItemsCompanion(
        timerSeconds: Value(seconds),
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
}
