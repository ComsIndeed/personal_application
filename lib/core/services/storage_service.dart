import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'app_prefs.dart';

class B2AuthResponse {
  final String apiUrl;
  final String authorizationToken;
  final String downloadUrl;
  final String accountId;

  B2AuthResponse({
    required this.apiUrl,
    required this.authorizationToken,
    required this.downloadUrl,
    required this.accountId,
  });

  factory B2AuthResponse.fromJson(Map<String, dynamic> json) {
    return B2AuthResponse(
      apiUrl: json['apiUrl'],
      authorizationToken: json['authorizationToken'],
      downloadUrl: json['downloadUrl'],
      accountId: json['accountId'],
    );
  }
}

class B2File {
  final String name;
  final String id;
  final int size;
  final DateTime uploadTimestamp;

  B2File({
    required this.name,
    required this.id,
    required this.size,
    required this.uploadTimestamp,
  });
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _prefs = AppPrefs();
  B2AuthResponse? _cachedAuth;

  Future<B2AuthResponse> _authorize() async {
    if (_prefs.b2KeyId.isEmpty || _prefs.b2AppKey.isEmpty) {
      throw Exception('B2 Credentials not set in settings');
    }

    final basicAuth = base64Encode(
      utf8.encode('${_prefs.b2KeyId}:${_prefs.b2AppKey}'),
    );

    final response = await http.get(
      Uri.parse('https://api.backblazeb2.com/b2api/v3/b2_authorize_account'),
      headers: {'Authorization': 'Basic $basicAuth'},
    );

    if (response.statusCode != 200) {
      throw Exception('B2 Authorization failed: ${response.body}');
    }

    _cachedAuth = B2AuthResponse.fromJson(jsonDecode(response.body));
    return _cachedAuth!;
  }

  Future<String> _getBucketId(B2AuthResponse auth) async {
    if (_prefs.b2BucketName.isEmpty) throw Exception('Bucket name not set');

    final response = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v3/b2_list_buckets'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'accountId': auth.accountId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list buckets: ${response.body}');
    }

    final buckets = jsonDecode(response.body)['buckets'] as List;
    final bucket = buckets.firstWhere(
      (b) => b['bucketName'] == _prefs.b2BucketName,
      orElse: () =>
          throw Exception('Bucket "${_prefs.b2BucketName}" not found'),
    );

    return bucket['bucketId'];
  }

  Future<void> uploadFile(PlatformFile file) async {
    final auth = await _authorize();
    final bucketId = await _getBucketId(auth);

    // Get upload URL
    final uploadResponse = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v3/b2_get_upload_url'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'bucketId': bucketId}),
    );

    if (uploadResponse.statusCode != 200) {
      throw Exception('Failed to get upload URL: ${uploadResponse.body}');
    }

    final uploadData = jsonDecode(uploadResponse.body);
    final uploadUrl = uploadData['uploadUrl'];
    final uploadToken = uploadData['authorizationToken'];

    Uint8List fileBytes;
    if (file.bytes != null) {
      fileBytes = file.bytes!;
    } else {
      if (file.path == null) throw Exception('File path is null');
      fileBytes = await io.File(file.path!).readAsBytes();
    }

    final sha1Hash = sha1.convert(fileBytes).toString();

    final response = await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': uploadToken,
        'X-Bz-File-Name': Uri.encodeComponent(file.name),
        'Content-Type': 'b2/x-auto',
        'Content-Length': fileBytes.length.toString(),
        'X-Bz-Content-Sha1': sha1Hash,
      },
      body: fileBytes,
    );

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.body}');
    }
  }

  Future<List<B2File>> listFiles() async {
    final auth = await _authorize();
    final bucketId = await _getBucketId(auth);

    final response = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v3/b2_list_file_names'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'bucketId': bucketId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list files: ${response.body}');
    }

    final files = jsonDecode(response.body)['files'] as List;
    return files.map((f) {
      return B2File(
        name: f['fileName'],
        id: f['fileId'],
        size: f['size'],
        uploadTimestamp: DateTime.fromMillisecondsSinceEpoch(
          f['uploadTimestamp'],
        ),
      );
    }).toList();
  }

  Future<void> deleteFile(String fileName, String fileId) async {
    final auth = await _authorize();

    final response = await http.post(
      Uri.parse('${auth.apiUrl}/b2api/v3/b2_delete_file_version'),
      headers: {'Authorization': auth.authorizationToken},
      body: jsonEncode({'fileName': fileName, 'fileId': fileId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.body}');
    }
  }

  Future<String> getDownloadUrl(String fileName) async {
    final auth = _cachedAuth ?? await _authorize();
    return '${auth.downloadUrl}/file/${_prefs.b2BucketName}/${Uri.encodeComponent(fileName)}';
  }
}
