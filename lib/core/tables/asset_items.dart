import 'package:drift/drift.dart';
import 'package:syncable/syncable.dart';
import 'package:uuid/uuid.dart';

import '../models/asset_item.dart';

@UseRowClass(AssetItem)
class AssetItems extends Table implements SyncableTable {
  // --- Syncable required ---
  @override
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  @override
  TextColumn get userId => text().nullable()();
  @override
  DateTimeColumn get updatedAt => dateTime()();
  @override
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  // --- B2 cloud fields (null = upload pending) ---
  TextColumn get b2FileId => text().nullable()();
  TextColumn get b2FileName => text().nullable()();
  DateTimeColumn get b2UpdatedAt => dateTime().nullable()();

  // --- Metadata ---
  TextColumn get displayName => text().nullable()();
  TextColumn get group => text().nullable()();
  TextColumn get mimeType => text()();
  IntColumn get size => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // --- Device-local cache (never synced to Supabase) ---
  BlobColumn get cachedBytes => blob().nullable()();
  DateTimeColumn get cachedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
