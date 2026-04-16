import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Metadata record for a file stored in Backblaze B2.
///
/// [cachedBytes] / [cachedAt] are nullable — populated on demand.
/// Cache is considered fresh when [cachedAt] >= [b2UpdatedAt].
class AssetItems extends Table {
  /// Local UUID — use this as the stable reference everywhere in the app.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// B2's own file ID — required for delete-by-version calls.
  TextColumn get b2FileId => text()();

  /// Key in the bucket, e.g. `<uuid>/<original_name.ext>`.
  TextColumn get b2FileName => text()();

  /// B2 upload timestamp — source of truth for cache freshness.
  DateTimeColumn get b2UpdatedAt => dateTime()();

  /// Optional human-readable label. Null = use original filename.
  TextColumn get displayName => text().nullable()();

  /// Optional grouping tag, e.g. "brain_dump", "avatars".
  TextColumn get group => text().nullable()();

  /// MIME type, e.g. "image/png".
  TextColumn get mimeType => text()();

  /// File size in bytes.
  IntColumn get size => integer()();

  /// When this record was first inserted locally.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Locally cached file bytes. Null = not yet downloaded / cache cleared.
  BlobColumn get cachedBytes => blob().nullable()();

  /// When [cachedBytes] was last written. Null if never cached.
  DateTimeColumn get cachedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
