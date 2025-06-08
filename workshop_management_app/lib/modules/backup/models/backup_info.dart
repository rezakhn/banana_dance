class BackupInfo {
  final int? id;
  final DateTime backupDate;
  final String filePath;
  final int? fileSize; // in bytes
  final String? status; // e.g., "Success", "Failed"
  final String? notes;  // User or system notes

  BackupInfo({
    this.id,
    required this.backupDate,
    required this.filePath,
    this.fileSize,
    this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // Store dates as ISO8601 strings (YYYY-MM-DD HH:MM:SS.SSS) for SQLite
      'backup_date': backupDate.toIso8601String(),
      'file_path': filePath,
      'file_size': fileSize,
      'status': status,
      'notes': notes,
    };
  }

  factory BackupInfo.fromMap(Map<String, dynamic> map) {
    return BackupInfo(
      id: map['id'],
      backupDate: DateTime.parse(map['backup_date']),
      filePath: map['file_path'],
      fileSize: map['file_size'],
      status: map['status'],
      notes: map['notes'],
    );
  }

  @override
  String toString() {
    return 'BackupInfo{id: $id, date: $backupDate, path: $filePath, size: $fileSize, status: $status}';
  }
}
