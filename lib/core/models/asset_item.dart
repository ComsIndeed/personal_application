import 'package:drift/drift.dart' hide JsonKey;
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncable/syncable.dart';

import '../database/app_database.dart';

part 'asset_item.g.dart';

/// Asset record. Synced to Supabase via [syncable] (metadata only).
/// [cachedBytes] and [cachedAt] are device-local and excluded from JSON.
@JsonSerializable(explicitToJson: true)
class AssetItem extends Equatable implements Syncable {
  const AssetItem({
    required this.id,
    required this.userId,
    required this.updatedAt,
    required this.deleted,
    this.b2FileId,
    this.b2FileName,
    this.b2UpdatedAt,
    this.displayName,
    this.group,
    required this.mimeType,
    required this.size,
    required this.createdAt,
    // Local-only — not part of toJson/fromJson
    this.cachedBytes,
    this.cachedAt,
  });

  factory AssetItem.fromJson(Map<String, dynamic> json) =>
      _$AssetItemFromJson(json);

  // --- Syncable required ---
  @override
  final String id;
  @override
  final String? userId;
  @override
  final DateTime updatedAt;
  @override
  final bool deleted;

  // --- B2 cloud fields ---
  final String? b2FileId;
  final String? b2FileName;
  final DateTime? b2UpdatedAt;

  // --- Metadata ---
  final String? displayName;
  final String? group;
  final String mimeType;
  final int size;
  final DateTime createdAt;

  // --- Device-local cache (excluded from toJson) ---
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<int>? cachedBytes;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final DateTime? cachedAt;

  /// Whether the file has been uploaded to B2.
  bool get isUploaded => b2FileId != null;

  /// Whether bytes are cached locally and fresh relative to B2.
  bool get isCacheFresh =>
      cachedBytes != null &&
      cachedAt != null &&
      (b2UpdatedAt == null || !cachedAt!.isBefore(b2UpdatedAt!));

  @override
  Map<String, dynamic> toJson() => _$AssetItemToJson(this);

  @override
  UpdateCompanion<AssetItem> toCompanion() {
    return AssetItemsCompanion(
          id: Value(id),
          userId: Value(userId),
          updatedAt: Value(updatedAt),
          deleted: Value(deleted),
          b2FileId: Value(b2FileId),
          b2FileName: Value(b2FileName),
          b2UpdatedAt: Value(b2UpdatedAt),
          displayName: Value(displayName),
          group: Value(group),
          mimeType: Value(mimeType),
          size: Value(size),
          createdAt: Value(createdAt),
        )
        as UpdateCompanion<AssetItem>;
  }

  AssetItem copyWith({
    String? id,
    String? userId,
    DateTime? updatedAt,
    bool? deleted,
    String? b2FileId,
    String? b2FileName,
    DateTime? b2UpdatedAt,
    String? displayName,
    String? group,
    String? mimeType,
    int? size,
    DateTime? createdAt,
    List<int>? cachedBytes,
    DateTime? cachedAt,
  }) {
    return AssetItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      b2FileId: b2FileId ?? this.b2FileId,
      b2FileName: b2FileName ?? this.b2FileName,
      b2UpdatedAt: b2UpdatedAt ?? this.b2UpdatedAt,
      displayName: displayName ?? this.displayName,
      group: group ?? this.group,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      cachedBytes: cachedBytes ?? this.cachedBytes,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, updatedAt, deleted];

  @override
  bool get stringify => true;
}
