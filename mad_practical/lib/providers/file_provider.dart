import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/file_model.dart';
import '../models/file_version.dart';
import '../models/file_comment.dart';
import '../services/api_service.dart';

class FileProvider extends ChangeNotifier {
  List<FileModel> _files = [];
  List<FileVersion> _versions = [];
  List<FileComment> _comments = [];
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isOffline = false;

  List<FileModel> get files => _files;
  List<FileVersion> get versions => _versions;
  List<FileComment> get comments => _comments;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  bool get isOffline => _isOffline;

  // Hive box names
  static const String _filesBoxName = 'files_cache';
  static const String _versionsBoxName = 'versions_cache';
  static const String _commentsBoxName = 'comments_cache';

  // ─── FILES ───────────────────────────────────────────────

  /// Fetch all files from API, fall back to Hive cache on failure
  Future<void> fetchFiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _files = await ApiService.getAllFiles();
      _isOffline = false;
      _statusMessage = 'Synced from server';

      // Cache to Hive
      final box = await Hive.openBox<FileModel>(_filesBoxName);
      await box.clear();
      for (int i = 0; i < _files.length; i++) {
        await box.put(_files[i].id, _files[i]);
      }
    } catch (e) {
      // Fall back to Hive cache
      _isOffline = true;
      _statusMessage = 'Using cached data';

      try {
        final box = await Hive.openBox<FileModel>(_filesBoxName);
        _files = box.values.toList();
      } catch (_) {
        _files = [];
        _statusMessage = 'No cached data available';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new file via API
  Future<bool> createFile({
    required String fileName,
    required String fileType,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check for duplicate in local list first
      final duplicate = _files.any(
        (f) => f.fileName.toLowerCase() == fileName.trim().toLowerCase(),
      );
      if (duplicate) {
        _statusMessage = 'A file with this name already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final file = await ApiService.createFile(
        fileName: fileName,
        fileType: fileType,
        description: description,
      );

      _files.insert(0, file);
      _statusMessage = 'File created successfully';

      // Update cache
      final box = await Hive.openBox<FileModel>(_filesBoxName);
      await box.put(file.id, file);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload a local file via multipart POST
  Future<bool> uploadFile({
    required String fileName,
    required String fileType,
    required String description,
    required Uint8List fileBytes,
    required String originalName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final duplicate = _files.any(
        (f) => f.fileName.toLowerCase() == fileName.trim().toLowerCase(),
      );
      if (duplicate) {
        _statusMessage = 'A file with this name already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final file = await ApiService.uploadFile(
        fileName: fileName,
        fileType: fileType,
        description: description,
        fileBytes: fileBytes,
        originalName: originalName,
      );

      _files.insert(0, file);
      _statusMessage = 'File uploaded successfully';

      final box = await Hive.openBox<FileModel>(_filesBoxName);
      await box.put(file.id, file);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a file via API
  Future<bool> deleteFile(String id) async {
    try {
      await ApiService.deleteFile(id);
      _files.removeWhere((f) => f.id == id);
      _statusMessage = 'File deleted successfully';

      // Remove from cache
      final box = await Hive.openBox<FileModel>(_filesBoxName);
      await box.delete(id);

      // Also clear cached versions and comments for this file
      final vBox = await Hive.openBox<FileVersion>(_versionsBoxName);
      final vKeys = vBox.keys.where((k) => k.toString().startsWith(id));
      for (final key in vKeys) {
        await vBox.delete(key);
      }

      final cBox = await Hive.openBox<FileComment>(_commentsBoxName);
      final cKeys = cBox.keys.where((k) => k.toString().startsWith(id));
      for (final key in cKeys) {
        await cBox.delete(key);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Failed to delete file';
      notifyListeners();
      return false;
    }
  }

  /// Toggle share status
  Future<bool> toggleShare(String id, bool isShared) async {
    try {
      final updated =
          await ApiService.updateFile(id, {'isShared': isShared});

      final index = _files.indexWhere((f) => f.id == id);
      if (index != -1) {
        _files[index] = updated;
      }
      _statusMessage = isShared ? 'File shared' : 'File unshared';

      // Update cache
      final box = await Hive.openBox<FileModel>(_filesBoxName);
      await box.put(id, updated);

      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Failed to update sharing status';
      notifyListeners();
      return false;
    }
  }

  /// Resolve conflict
  Future<bool> resolveConflict(String id, String resolution) async {
    try {
      final updated = await ApiService.updateFile(id, {
        'conflictResolution': resolution,
        'hasConflict': false,
      });

      final index = _files.indexWhere((f) => f.id == id);
      if (index != -1) {
        _files[index] = updated;
      }
      _statusMessage = 'Conflict resolved';

      final box = await Hive.openBox<FileModel>(_filesBoxName);
      await box.put(id, updated);

      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Failed to resolve conflict';
      notifyListeners();
      return false;
    }
  }

  // ─── VERSIONS ────────────────────────────────────────────

  /// Fetch versions for a file
  Future<void> fetchVersions(String fileId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _versions = await ApiService.getVersions(fileId);
      _isOffline = false;

      // Cache versions
      final box = await Hive.openBox<FileVersion>(_versionsBoxName);
      // Remove old versions for this file
      final oldKeys =
          box.keys.where((k) => k.toString().startsWith(fileId)).toList();
      for (final key in oldKeys) {
        await box.delete(key);
      }
      for (final v in _versions) {
        await box.put('${fileId}_${v.id}', v);
      }
    } catch (e) {
      _isOffline = true;
      try {
        final box = await Hive.openBox<FileVersion>(_versionsBoxName);
        _versions = box.values
            .where((v) => v.fileId == fileId)
            .toList()
          ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
      } catch (_) {
        _versions = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new version
  Future<bool> createVersion({
    required String fileId,
    required String note,
  }) async {
    try {
      final version = await ApiService.createVersion(
        fileId: fileId,
        note: note,
      );
      _versions.insert(0, version);
      _statusMessage = 'Version created';

      final box = await Hive.openBox<FileVersion>(_versionsBoxName);
      await box.put('${fileId}_${version.id}', version);

      // Re-fetch files to get updated conflict status
      await fetchFiles();

      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Failed to create version';
      notifyListeners();
      return false;
    }
  }

  // ─── COMMENTS ────────────────────────────────────────────

  /// Fetch comments for a file
  Future<void> fetchComments(String fileId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _comments = await ApiService.getComments(fileId);
      _isOffline = false;

      // Cache comments
      final box = await Hive.openBox<FileComment>(_commentsBoxName);
      final oldKeys =
          box.keys.where((k) => k.toString().startsWith(fileId)).toList();
      for (final key in oldKeys) {
        await box.delete(key);
      }
      for (final c in _comments) {
        await box.put('${fileId}_${c.id}', c);
      }
    } catch (e) {
      _isOffline = true;
      try {
        final box = await Hive.openBox<FileComment>(_commentsBoxName);
        _comments = box.values
            .where((c) => c.fileId == fileId)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } catch (_) {
        _comments = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a comment
  Future<bool> addComment({
    required String fileId,
    required String text,
  }) async {
    try {
      final comment = await ApiService.createComment(
        fileId: fileId,
        text: text,
      );
      _comments.insert(0, comment);
      _statusMessage = 'Comment added';

      final box = await Hive.openBox<FileComment>(_commentsBoxName);
      await box.put('${fileId}_${comment.id}', comment);

      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Failed to add comment';
      notifyListeners();
      return false;
    }
  }

  // ─── SYNC ────────────────────────────────────────────────

  /// Full sync from server
  Future<void> syncAll() async {
    _isLoading = true;
    _statusMessage = 'Syncing...';
    notifyListeners();

    await fetchFiles();
  }
}
