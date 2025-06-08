import 'dart:io'; // For File object if listing files directly
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // Added for notes default
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database_service.dart';
import '../models/backup_info.dart';
import '../services/backup_service.dart';

class BackupController with ChangeNotifier {
  final BackupService _backupService = BackupService();
  final DatabaseService _dbService = DatabaseService();

  List<BackupInfo> _backupHistory = [];
  List<BackupInfo> get backupHistory => _backupHistory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _operationMessage;
  String? get operationMessage => _operationMessage;
  bool _isError = false;
  bool get isError => _isError;


  BackupController() {
    fetchBackupHistory();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _operationMessage = null;
    _isError = false;
    notifyListeners();
  }

  void _setMessage(String message, {bool isError = false}) {
    _operationMessage = message;
    _isError = isError;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBackupHistory() async {
    _setLoading(true);
    try {
      _backupHistory = await _dbService.getBackupHistory();
    } catch (e) {
      _setMessage('Failed to load backup history: ${e.toString()}', isError: true);
    }
    _setLoading(false);
  }

  Future<bool> _requestStoragePermission() async {
    // On Android, for getApplicationDocumentsDirectory, explicit permission is usually not needed.
    // However, if the path were to change to external shared storage, this would be crucial.
    // For API 30+ manageExternalStorage might be needed for broad access, but not for app-specific dirs.
    // Storage permission (Manifest.permission.WRITE_EXTERNAL_STORAGE and READ_EXTERNAL_STORAGE)
    // is generally what's requested for older APIs or if writing to shared external dirs.

    // Let's check for general storage permission.
    // For Android 13+ (API 33), specific media permissions (photos, video, audio) are used instead of broad storage.
    // For non-media files, no specific permission is needed for app's own directories.
    // This check is more of a placeholder for if we were writing to less restricted locations.
    if (Platform.isAndroid) { // Only typically relevant for Android
        var status = await Permission.storage.status;
        if (!status.isGranted) {
            status = await Permission.storage.request();
        }
        if (status.isPermanentlyDenied) {
            // Guide user to app settings
            _setMessage("Storage permission is permanently denied. Please enable it in app settings to create backups.", isError: true);
            // Consider adding openAppSettings();
            return false;
        }
        return status.isGranted;
    }
    return true; // Assume granted or not needed for other platforms for app-specific dirs
  }

  Future<void> createNewBackup({String? notes}) async {
    _setLoading(true);

    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission && Platform.isAndroid) {
      if (_operationMessage == null || !_isError) {
          _setMessage("Storage permission denied. Cannot create backup.", isError: true);
      }
      _setLoading(false);
      return;
    }

    final result = await _backupService.createBackup();

    if (result['success'] == true) {
      final backupInfo = BackupInfo(
        backupDate: DateTime.now(),
        filePath: result['filePath'],
        fileSize: result['fileSize'],
        status: 'Success',
        notes: notes != null && notes.isNotEmpty ? notes : 'Manual backup on ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
      );
      try {
        await _dbService.insertBackupInfo(backupInfo);
        await fetchBackupHistory();
        _setMessage(result['message'] ?? 'Backup created successfully!', isError: false);
      } catch (dbError) {
        _setMessage('Backup file created, but failed to save history: ${dbError.toString()}', isError: true);
      }
    } else {
      _setMessage(result['message'] ?? 'Backup creation failed.', isError: true);
    }
  }

  Future<void> restoreFromBackup(BackupInfo backupToRestore) async {
    _setLoading(true);

    try {
      await _dbService.close();
    } catch (e) {
       _setMessage('Critical error: Could not close current database before restore. Restore aborted. ${e.toString()}', isError: true);
       return;
    }

    final result = await _backupService.restoreBackup(backupToRestore.filePath);

    if (result['success'] == true) {
      _setMessage('${result['message']}. You MUST restart the application now.', isError: false);
      await fetchBackupHistory();
    } else {
      _setMessage(result['message'] ?? 'Restore failed.', isError: true);
      try {
        await _dbService.database;
      } catch (e) {
        print("Failed to re-initialize database after failed restore: $e");
      }
    }
  }

  Future<void> deleteBackup(BackupInfo backupToDelete) async {
    _setLoading(true);
    bool fileDeleted = await _backupService.deleteBackupFile(backupToDelete.filePath);

    if (fileDeleted) {
      try {
        await _dbService.deleteBackupInfo(backupToDelete.id!);
        await fetchBackupHistory();
        _setMessage('Backup file and history entry deleted successfully.', isError: false);
      } catch (dbError) {
        _setMessage('Backup file deleted, but failed to delete history entry: ${dbError.toString()}', isError: true);
      }
    } else {
      _setMessage('Failed to delete backup file. History entry not deleted.', isError: true);
    }
  }

  Future<void> clearAllBackupHistoryAndFiles() async {
    _setLoading(true);
    try {
      final history = await _dbService.getBackupHistory();
      for (var backupInfo in history) {
        await _backupService.deleteBackupFile(backupInfo.filePath);
      }
      await _dbService.clearBackupHistory();
      await fetchBackupHistory();
      _setMessage('All backup history and associated files deleted.', isError: false);
    } catch (e) {
      _setMessage('Error clearing backup history/files: ${e.toString()}', isError: true);
    }
  }
}
