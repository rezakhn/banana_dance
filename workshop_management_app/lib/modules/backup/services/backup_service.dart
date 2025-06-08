import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart'; // For timestamp formatting
// Assuming DatabaseService._dbName is accessible or hardcoded if not.
// For this example, let's assume the db name is known or can be fetched.
// We can't directly access private members of another class.
// Let's use a const for the DB name, consistent with DatabaseService.
const String _dbNameConst = "workshop_management.db";


class BackupService {

  Future<Directory> _getBackupDirectory() async {
    // Using application documents directory, which is generally always accessible.
    // For backups visible to the user outside the app, getExternalStorageDirectory (Android)
    // or similar would be needed, along with stricter permission handling.
    final appDocsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDocsDir.path, 'Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<Map<String, dynamic>> createBackup() async {
    try {
      final dbFolder = await getDatabasesPath();
      final originalDbFile = File(p.join(dbFolder, _dbNameConst));

      if (!await originalDbFile.exists()) {
        return {'success': false, 'message': 'Original database file not found.'};
      }

      final backupDir = await _getBackupDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'workshop_backup_$timestamp.db';
      final backupFile = File(p.join(backupDir.path, backupFileName));

      await originalDbFile.copy(backupFile.path);

      final fileSize = await backupFile.length();

      return {
        'success': true,
        'message': 'Backup created successfully at ${backupFile.path}',
        'filePath': backupFile.path,
        'fileName': backupFileName,
        'fileSize': fileSize,
      };
    } catch (e) {
      print('Error creating backup: $e');
      return {'success': false, 'message': 'Backup creation failed: ${e.toString()}'};
    }
  }

  Future<List<File>> listBackupFiles() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        return []; // No backup directory, so no backups
      }

      final files = backupDir.listSync()
          .where((entity) => entity is File && p.basename(entity.path).startsWith('workshop_backup_') && p.basename(entity.path).endsWith('.db'))
          .cast<File>()
          .toList();

      // Sort by date, newest first (derived from filename)
      files.sort((a, b) {
        // Extract timestamp from filename, e.g. workshop_backup_YYYYMMDD_HHMMSS.db
        String aName = p.basename(a.path);
        String bName = p.basename(b.path);
        // This assumes fixed prefix "workshop_backup_" (16 chars) and suffix ".db" (3 chars)
        String aTimestamp = aName.substring(16, aName.length - 3);
        String bTimestamp = bName.substring(16, bName.length - 3);
        return bTimestamp.compareTo(aTimestamp); // Descending
      });
      return files;

    } catch (e) {
      print('Error listing backup files: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> restoreBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return {'success': false, 'message': 'Selected backup file not found.'};
      }

      final dbFolder = await getDatabasesPath();
      final currentDbPath = p.join(dbFolder, _dbNameConst);
      final currentDbFile = File(currentDbPath);

      // IMPORTANT: The active database connection must be closed BEFORE replacing the file.
      // This service cannot directly close DatabaseService's private _database instance.
      // The calling layer (Controller) must ensure DatabaseService().close() is called.
      // For this example, we assume this is handled by the caller.
      // A warning: if not closed, restore might fail or corrupt the DB.

      if (await currentDbFile.exists()) {
        // Optionally, create a backup of the current DB before overwriting, e.g., currentDbPath + ".pre_restore_backup"
        // await currentDbFile.rename(currentDbPath + ".pre_restore_backup_" + DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()));
        await currentDbFile.delete(); // Delete current DB to ensure clean restore
      }

      await backupFile.copy(currentDbPath);

      // The application will need to re-initialize DatabaseService to use the restored DB.
      // This typically means restarting the app or having a mechanism to re-init services.
      return {'success': true, 'message': 'Database restored successfully from ${p.basename(backupFilePath)}. Please restart the app.'};

    } catch (e) {
      print('Error restoring backup: $e');
      return {'success': false, 'message': 'Restore failed: ${e.toString()}'};
    }
  }

  Future<bool> deleteBackupFile(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (await backupFile.exists()) {
        await backupFile.delete();
        return true;
      }
      return false; // File didn't exist
    } catch (e) {
      print('Error deleting backup file: $e');
      return false;
    }
  }
}
