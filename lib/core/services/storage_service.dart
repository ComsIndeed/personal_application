import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'app_prefs.dart';

// ---------------------------------------------------------------------------
// Internal B2 auth response
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
  /// Records that exist in both Drift and B2 — all good.
  final List<AssetItem> synced;

  /// B2 keys that have no matching Drift record — orphan files in the bucket.
  final List<String> orphanB2Keys;

  /// Drift records whose [b2FileName] was not found in the bucket.
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

/// Abstracts all file I/O between the app, Backblaze B2, and the local
/// Drift database.
///
/// - **Upload** — auto-generates a bucket key, saves B2 metadata to Drift.
/// - **Download** — serves from local cache when fresh; fetches from B2 otherwise.
/// - **List** — reads from Drift (fast, offline-capable).
/// - **Sync** — reconciles Drift vs B2 bucket and reports orphans.
/// - **Delete** — removes from both B2 and Drift.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _prefs = AppPrefs();
  _B2Auth? _cachedAuth;
  String? _cachedBucketId;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Upload a file chosen via [file_picker].
  ///
  /// [displayName] — optional human label shown in the UI.
  /// [group] — optional tag for filtering, e.g. `"brain_dump"`.
  Future<AssetItem> upload(
    PlatformFile file, {
    String? displayName,
    String? group,
  }) async {
    final bytes = await _resolveBytes(file);
    final mime = _guessMime(file.name);
    return uploadBytes(
      bytes,
      file.name,
      mime,
      displayName: displayName,
      group: group,
    );
  }

  /// Upload raw bytes.
  ///
  /// [filename] is used for the bucket key suffix and MIME guessing.
  Future<AssetItem> uploadBytes(
    Uint8List bytes,
    String filename,
    String mimeType, {
    String? displayName,
    String? group,
  }) async {
    final auth = await _authorize();
    final bucketId = await _getBucketId(auth);
    final bucketKey = '${const Uuid().v4()}/$filename';

    // --- Get upload URL ---
    final urlResp = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v2/b2_get_upload_url'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'bucketId': bucketId}),
    );
    _assertOk(urlResp, 'get upload URL');

    final urlData = jsonDecode(urlResp.body);
    final uploadUrl = urlData['uploadUrl'] as String;
    final uploadToken = urlData['authorizationToken'] as String;

    // --- Upload ---
    final sha1Hash = sha1.convert(bytes).toString();
    final uploadResp = await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': uploadToken,
        'X-Bz-File-Name': Uri.encodeComponent(bucketKey),
        'Content-Type': mimeType,
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

    // --- Save Drift record ---
    final db = AppDatabase();
    final companion = AssetItemsCompanion.insert(
      b2FileId: b2FileId,
      b2FileName: bucketKey,
      b2UpdatedAt: b2Timestamp,
      mimeType: mimeType,
      size: bytes.length,
      displayName: Value(displayName),
      group: Value(group),
    );
    final id = await db.into(db.assetItems).insertReturning(companion);
    return id;
  }

  /// Download file bytes for [record].
  ///
  /// Returns cached bytes when fresh ([cachedAt] >= [b2UpdatedAt]).
  /// Set [forceRefresh] to always re-fetch from B2.
  Future<Uint8List> download(
    AssetItem record, {
    bool forceRefresh = false,
  }) async {
    final isFresh =
        record.cachedBytes != null &&
        record.cachedAt != null &&
        !record.cachedAt!.isBefore(record.b2UpdatedAt);

    if (!forceRefresh && isFresh) {
      return record.cachedBytes!;
    }

    // Fetch from B2
    final auth = await _authorize();
    final url =
        '${auth.downloadUrl}/file/${_prefs.b2BucketName.trim()}/${Uri.encodeComponent(record.b2FileName)}';

    final resp = await http.get(
      Uri.parse(url),
      headers: {'Authorization': auth.authorizationToken},
    );
    _assertOk(resp, 'download');

    final bytes = resp.bodyBytes;
    final now = DateTime.now();

    // Update cache in Drift
    final db = AppDatabase();
    await (db.update(
      db.assetItems,
    )..where((t) => t.id.equals(record.id))).write(
      AssetItemsCompanion(cachedBytes: Value(bytes), cachedAt: Value(now)),
    );

    return bytes;
  }

  /// List all asset records from Drift.
  ///
  /// Optionally filter by [group].
  Future<List<AssetItem>> listFiles({String? group}) async {
    final db = AppDatabase();
    final q = db.select(db.assetItems);
    if (group != null) {
      q.where((t) => t.group.equals(group));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  /// Reconcile Drift records against the live B2 bucket.
  ///
  /// Reports orphans on both sides — does NOT auto-fix.
  /// Call [delete] on [SyncResult.orphanRecords] or handle [SyncResult.orphanB2Keys]
  /// as needed.
  Future<SyncResult> sync() async {
    final auth = await _authorize();
    final bucketId = await _getBucketId(auth);

    // Fetch all B2 file names
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
    final recordKeys = {for (final r in records) r.b2FileName: r};

    final synced = <AssetItem>[];
    final orphanRecords = <AssetItem>[];

    for (final r in records) {
      if (b2Keys.contains(r.b2FileName)) {
        synced.add(r);
      } else {
        orphanRecords.add(r);
      }
    }

    final orphanB2Keys = b2Keys
        .where((k) => !recordKeys.containsKey(k))
        .toList();

    return SyncResult(
      synced: synced,
      orphanB2Keys: orphanB2Keys,
      orphanRecords: orphanRecords,
    );
  }

  /// Delete [record] from both B2 and Drift.
  Future<void> delete(AssetItem record) async {
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

    final db = AppDatabase();
    await (db.delete(db.assetItems)..where((t) => t.id.equals(record.id))).go();
  }

  /// Clear local cache for [record] without touching B2.
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

  /// Verify credentials and bucket access. Throws on failure.
  Future<void> verifyCredentials() async {
    final auth = await _authorize();
    await _getBucketId(auth);
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

  void _assertOk(http.Response resp, String op) {
    if (resp.statusCode != 200) {
      throw Exception('B2 $op failed (${resp.statusCode}): ${resp.body}');
    }
  }
}
