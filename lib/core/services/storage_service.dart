import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/asset_item.dart';
import 'app_prefs.dart';

// ---------------------------------------------------------------------------
// Internal B2 auth
// ---------------------------------------------------------------------------

class _B2Auth {
  final String apiUrl;
  final String authorizationToken;
  final String downloadUrl;
  final String accountId;

  _B2Auth({
    required this.apiUrl,
    required this.authorizationToken,
    required this.downloadUrl,
    required this.accountId,
  });

  factory _B2Auth.fromJson(Map<String, dynamic> json) => _B2Auth(
    apiUrl: json['apiUrl'],
    authorizationToken: json['authorizationToken'],
    downloadUrl: json['downloadUrl'],
    accountId: json['accountId'],
  );
}

// ---------------------------------------------------------------------------
// Sync result
// ---------------------------------------------------------------------------

class SyncResult {
  final List<AssetItem> synced;
  final List<String> orphanB2Keys;
  final List<AssetItem> orphanRecords;

  const SyncResult({
    required this.synced,
    required this.orphanB2Keys,
    required this.orphanRecords,
  });

  bool get isClean => orphanB2Keys.isEmpty && orphanRecords.isEmpty;
}

// ---------------------------------------------------------------------------
// StorageService
// ---------------------------------------------------------------------------

/// Local-first file management with automatic B2 cloud backup.
///
/// **Import** caches bytes immediately so files are usable right away,
/// then uploads to B2 in the background. Records sync across devices
/// via [SyncService].
///
/// Public API:
/// - [import] / [importBytes] — add a file
/// - [getBytes] — retrieve bytes (cache-first, B2 fallback)
/// - [uploadingIds] — stream of IDs currently being uploaded
/// - [listFiles] — all records, optionally filtered by group
/// - [delete] — remove from Drift + B2
/// - [sync] — reconcile Drift vs B2 bucket
/// - [verifyCredentials] — test B2 connection
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _prefs = AppPrefs();
  _B2Auth? _cachedAuth;
  String? _cachedBucketId;

  final _uploadingIds = StreamController<Set<String>>.broadcast();
  final _currentlyUploading = <String>{};

  /// Broadcast stream of asset IDs currently being uploaded to B2.
  Stream<Set<String>> get uploadingIds => _uploadingIds.stream;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Import a file from [file_picker].
  ///
  /// Caches bytes immediately → file is usable before upload completes.
  /// Background upload to B2 starts automatically.
  Future<AssetItem> import(
    PlatformFile file, {
    String? displayName,
    String? group,
  }) async {
    final bytes = await _resolveBytes(file);
    return importBytes(
      bytes,
      file.name,
      _guessMime(file.name),
      displayName: displayName,
      group: group,
    );
  }

  /// Import raw bytes (generated content, screenshots, etc.).
  Future<AssetItem> importBytes(
    Uint8List bytes,
    String filename,
    String mimeType, {
    String? displayName,
    String? group,
  }) async {
    final db = AppDatabase();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final now = DateTime.now();

    // Insert with cache populated immediately
    final record = await db
        .into(db.assetItems)
        .insertReturning(
          AssetItemsCompanion.insert(
            userId: Value(userId),
            updatedAt: now,
            mimeType: mimeType,
            size: bytes.length,
            displayName: Value(displayName),
            group: Value(group),
            createdAt: Value(now),
            cachedBytes: Value(bytes),
            cachedAt: Value(now),
          ),
        );

    // Fire-and-forget upload
    _uploadInBackground(record, bytes);

    return record;
  }

  /// Retrieve bytes for [record].
  ///
  /// Returns cached bytes if [isCacheFresh] is true (or [checkFreshness] is false).
  /// Otherwise downloads from B2 and updates the cache.
  Future<Uint8List> getBytes(
    AssetItem record, {
    bool checkFreshness = true,
  }) async {
    // Use cache if available and either freshness check is off or cache is current
    if (record.cachedBytes != null &&
        (!checkFreshness || record.isCacheFresh)) {
      return Uint8List.fromList(record.cachedBytes!);
    }

    // No B2 yet — can only serve from cache
    if (!record.isUploaded) {
      if (record.cachedBytes != null) {
        return Uint8List.fromList(record.cachedBytes!);
      }
      throw StateError('Asset ${record.id} has no cache and no B2 upload yet');
    }

    // Check connectivity before hitting network
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (record.cachedBytes != null) {
        return Uint8List.fromList(record.cachedBytes!);
      }
      throw StateError('Offline and no local cache for asset ${record.id}');
    }

    return _fetchAndCache(record);
  }

  /// List asset records from Drift. Optionally filter by [group].
  Future<List<AssetItem>> listFiles({String? group}) async {
    final db = AppDatabase();
    final q = db.select(db.assetItems)..where((t) => t.deleted.equals(false));
    if (group != null) q.where((t) => t.group.equals(group));
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  /// Delete [record] from Drift and B2 (if uploaded).
  Future<void> delete(AssetItem record) async {
    if (record.isUploaded) {
      final auth = await _authorize();
      final resp = await http.post(
        Uri.parse('${auth.apiUrl}/b2api/v2/b2_delete_file_version'),
        headers: {'Authorization': auth.authorizationToken},
        body: jsonEncode({
          'fileName': record.b2FileName,
          'fileId': record.b2FileId,
        }),
      );
      _assertOk(resp, 'delete from B2');
    }

    final db = AppDatabase();
    await (db.delete(db.assetItems)..where((t) => t.id.equals(record.id))).go();
  }

  /// Clear local cache bytes without touching B2.
  Future<void> clearCache(AssetItem record) async {
    final db = AppDatabase();
    await (db.update(
      db.assetItems,
    )..where((t) => t.id.equals(record.id))).write(
      const AssetItemsCompanion(
        cachedBytes: Value(null),
        cachedAt: Value(null),
      ),
    );
  }

  /// Reconcile Drift records vs live B2 bucket. Reports orphans, does not auto-fix.
  Future<SyncResult> sync() async {
    final auth = await _authorize();
    final bucketId = await _getBucketId(auth);

    final b2Resp = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v2/b2_list_file_names'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'bucketId': bucketId, 'maxFileCount': 10000}),
    );
    _assertOk(b2Resp, 'list B2 files');

    final b2Keys = (jsonDecode(b2Resp.body)['files'] as List)
        .map((f) => f['fileName'] as String)
        .toSet();

    final records = await listFiles();
    final uploadedRecords = records.where((r) => r.isUploaded).toList();
    final recordKeys = {for (final r in uploadedRecords) r.b2FileName!: r};

    final synced = uploadedRecords
        .where((r) => b2Keys.contains(r.b2FileName))
        .toList();
    final orphanRecords = uploadedRecords
        .where((r) => !b2Keys.contains(r.b2FileName))
        .toList();
    final orphanB2Keys = b2Keys
        .where((k) => !recordKeys.containsKey(k))
        .toList();

    return SyncResult(
      synced: synced,
      orphanB2Keys: orphanB2Keys,
      orphanRecords: orphanRecords,
    );
  }

  /// Test B2 credentials and bucket access.
  Future<void> verifyCredentials() async {
    final auth = await _authorize();
    await _getBucketId(auth);
  }

  // -------------------------------------------------------------------------
  // Background upload
  // -------------------------------------------------------------------------

  void _uploadInBackground(AssetItem record, Uint8List bytes) {
    _setUploading(record.id, true);
    _doUpload(record, bytes)
        .then((_) {
          _setUploading(record.id, false);
        })
        .catchError((e) {
          // Upload failed — record stays with b2FileId null (retry later)
          _setUploading(record.id, false);
        });
  }

  Future<void> _doUpload(AssetItem record, Uint8List bytes) async {
    final auth = await _authorize();
    final bucketId = await _getBucketId(auth);
    final bucketKey =
        '${const Uuid().v4()}/${record.displayName ?? record.mimeType.split('/').last}';

    final urlResp = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v2/b2_get_upload_url'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'bucketId': bucketId}),
    );
    _assertOk(urlResp, 'get upload URL');

    final urlData = jsonDecode(urlResp.body);
    final uploadUrl = urlData['uploadUrl'] as String;
    final uploadToken = urlData['authorizationToken'] as String;

    final sha1Hash = sha1.convert(bytes).toString();
    final uploadResp = await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': uploadToken,
        'X-Bz-File-Name': Uri.encodeComponent(bucketKey),
        'Content-Type': record.mimeType,
        'Content-Length': bytes.length.toString(),
        'X-Bz-Content-Sha1': sha1Hash,
      },
      body: bytes,
    );
    _assertOk(uploadResp, 'upload');

    final b2Data = jsonDecode(uploadResp.body);
    final b2FileId = b2Data['fileId'] as String;
    final b2Timestamp = DateTime.fromMillisecondsSinceEpoch(
      b2Data['uploadTimestamp'] as int,
    );

    // Update Drift record with B2 fields + bump updatedAt for syncable
    final db = AppDatabase();
    final now = DateTime.now();
    await (db.update(
      db.assetItems,
    )..where((t) => t.id.equals(record.id))).write(
      AssetItemsCompanion(
        b2FileId: Value(b2FileId),
        b2FileName: Value(bucketKey),
        b2UpdatedAt: Value(b2Timestamp),
        updatedAt: Value(now),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Download & cache
  // -------------------------------------------------------------------------

  Future<Uint8List> _fetchAndCache(AssetItem record) async {
    final auth = await _authorize();
    final url =
        '${auth.downloadUrl}/file/${_prefs.b2BucketName.trim()}/${Uri.encodeComponent(record.b2FileName!)}';

    final resp = await http.get(
      Uri.parse(url),
      headers: {'Authorization': auth.authorizationToken},
    );
    _assertOk(resp, 'download');

    final bytes = resp.bodyBytes;
    final db = AppDatabase();
    await (db.update(
      db.assetItems,
    )..where((t) => t.id.equals(record.id))).write(
      AssetItemsCompanion(
        cachedBytes: Value(bytes),
        cachedAt: Value(DateTime.now()),
      ),
    );

    return bytes;
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  Future<_B2Auth> _authorize() async {
    if (_cachedAuth != null) return _cachedAuth!;
    final keyId = _prefs.b2KeyId.trim();
    final appKey = _prefs.b2AppKey.trim();
    if (keyId.isEmpty || appKey.isEmpty) {
      throw Exception('B2 credentials not set in settings');
    }
    final basicAuth = base64Encode(utf8.encode('$keyId:$appKey'));
    final resp = await http.get(
      Uri.parse('https://api.backblazeb2.com/b2api/v2/b2_authorize_account'),
      headers: {'Authorization': 'Basic $basicAuth'},
    );
    _assertOk(resp, 'B2 authorization');
    _cachedAuth = _B2Auth.fromJson(jsonDecode(resp.body));
    return _cachedAuth!;
  }

  Future<String> _getBucketId(_B2Auth auth) async {
    if (_cachedBucketId != null) return _cachedBucketId!;
    final bucketName = _prefs.b2BucketName.trim();
    if (bucketName.isEmpty) throw Exception('Bucket name not set');
    final resp = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v2/b2_list_buckets'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'accountId': auth.accountId}),
    );
    _assertOk(resp, 'list buckets');
    final buckets = jsonDecode(resp.body)['buckets'] as List;
    final bucket = buckets.firstWhere(
      (b) => b['bucketName'] == bucketName,
      orElse: () => throw Exception('Bucket "$bucketName" not found'),
    );
    _cachedBucketId = bucket['bucketId'] as String;
    return _cachedBucketId!;
  }

  Future<Uint8List> _resolveBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    if (file.path != null) return io.File(file.path!).readAsBytes();
    throw Exception('PlatformFile has no bytes or path');
  }

  String _guessMime(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'json': 'application/json',
      'zip': 'application/zip',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  void _setUploading(String id, bool uploading) {
    if (uploading) {
      _currentlyUploading.add(id);
    } else {
      _currentlyUploading.remove(id);
    }
    _uploadingIds.add(Set.unmodifiable(_currentlyUploading));
  }

  void _assertOk(http.Response resp, String op) {
    if (resp.statusCode != 200) {
      throw Exception('B2 $op failed (${resp.statusCode}): ${resp.body}');
    }
  }
}
