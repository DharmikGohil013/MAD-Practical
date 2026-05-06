import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/file_model.dart';
import '../models/file_version.dart';
import '../models/file_comment.dart';

class ApiService {
  static final String _baseUrl = ApiConfig.baseUrl;

  // ─── FILES ───────────────────────────────────────────────

  /// GET /api/files
  static Future<List<FileModel>> getAllFiles() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/files'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => FileModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load files: ${response.statusCode}');
    }
  }

  /// POST /api/files  (multipart — with actual file bytes)
  static Future<FileModel> uploadFile({
    required String fileName,
    required String fileType,
    required String description,
    required Uint8List fileBytes,
    required String originalName,
  }) async {
    final uri = Uri.parse('$_baseUrl/files');
    final request = http.MultipartRequest('POST', uri);

    request.fields['fileName'] = fileName;
    request.fields['fileType'] = fileType;
    request.fields['description'] = description;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: originalName,
      ),
    );

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return FileModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('A file with this name already exists');
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Failed to upload file');
    }
  }

  /// POST /api/files  (JSON — manual entry, no real file)
  static Future<FileModel> createFile({
    required String fileName,
    required String fileType,
    required String description,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/files'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'fileName': fileName,
            'fileType': fileType,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return FileModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('A file with this name already exists');
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Failed to create file');
    }
  }

  /// PUT /api/files/:id
  static Future<FileModel> updateFile(
      String id, Map<String, dynamic> updates) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/files/$id'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(updates),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return FileModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update file: ${response.statusCode}');
    }
  }

  /// DELETE /api/files/:id
  static Future<void> deleteFile(String id) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/files/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.statusCode}');
    }
  }

  // ─── VERSIONS ────────────────────────────────────────────

  /// GET /api/versions/:fileId
  static Future<List<FileVersion>> getVersions(String fileId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/versions/$fileId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => FileVersion.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load versions: ${response.statusCode}');
    }
  }

  /// POST /api/versions
  static Future<FileVersion> createVersion({
    required String fileId,
    required String note,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/versions'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'fileId': fileId,
            'note': note,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return FileVersion.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create version: ${response.statusCode}');
    }
  }

  // ─── COMMENTS ────────────────────────────────────────────

  /// GET /api/comments/:fileId
  static Future<List<FileComment>> getComments(String fileId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/comments/$fileId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => FileComment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  }

  /// POST /api/comments
  static Future<FileComment> createComment({
    required String fileId,
    required String text,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/comments'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'fileId': fileId,
            'text': text,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return FileComment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create comment: ${response.statusCode}');
    }
  }
}
