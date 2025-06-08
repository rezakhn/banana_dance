import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart';
import '../controllers/backup_controller.dart';
import '../models/backup_info.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<BackupController>(context, listen: false).fetchBackupHistory();
    });
  }

  Future<void> _performRestore(BackupController controller, BackupInfo backupInfo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Text(
            'Restoring from backup \'${p.basename(backupInfo.filePath)}\' (dated ${DateFormat.yMMMd().add_jm().format(backupInfo.backupDate)}) will OVERWRITE all current data. This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await controller.restoreFromBackup(backupInfo);
      if (mounted && controller.operationMessage != null && !controller.isError) {
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text("Restore Successful"),
                  content: Text("${controller.operationMessage}\nPlease restart the application for changes to take full effect."),
                  actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text("OK"))],
            )
        );
      }
    }
  }

  Future<void> _performDelete(BackupController controller, BackupInfo backupInfo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete Backup'),
        content: Text('Are you sure you want to delete the backup file and its history record for \'${p.basename(backupInfo.filePath)}\'? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Backup'),
          ),
        ],
      ),
    );
     if (confirm == true && mounted) {
      await controller.deleteBackup(backupInfo);
    }
  }

  Future<void> _performClearAll(BackupController controller) async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Clear All Backups'),
        content: const Text('Are you sure you want to delete ALL backup files and ALL backup history records? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await controller.clearAllBackupHistoryAndFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupController = Provider.of<BackupController>(context);

    final Widget screenBody = RefreshIndicator(
        onRefresh: () => backupController.fetchBackupHistory(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes for new backup (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Create New Backup Now'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 12)),
                    onPressed: backupController.isLoading
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            await backupController.createNewBackup(notes: _notesController.text.trim());
                            if (mounted && backupController.operationMessage != null && !backupController.isError) {
                                _notesController.clear();
                            }
                          },
                  ),
                  if (backupController.isLoading && backupController.operationMessage == null)
                     const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator())),
                  if (backupController.operationMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        backupController.operationMessage!,
                        style: TextStyle(color: backupController.isError ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Backup History (${backupController.backupHistory.length} entries)", style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: backupController.backupHistory.isEmpty && !backupController.isLoading
                  ? const Center(child: Text('No backup history found. Create a backup!'))
                  : ListView.builder(
                      itemCount: backupController.backupHistory.length,
                      itemBuilder: (context, index) {
                        final backupInfo = backupController.backupHistory[index];
                        final fileSizeMB = backupInfo.fileSize != null ? (backupInfo.fileSize! / (1024 * 1024)).toStringAsFixed(2) : "N/A";
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${DateFormat.yMMMd().add_jm().format(backupInfo.backupDate)}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text('File: ${p.basename(backupInfo.filePath)}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                if (backupInfo.fileSize != null) Text('Size: $fileSizeMB MB'),
                                if (backupInfo.status != null)
                                  Text('Status: ${backupInfo.status}', style: TextStyle(color: backupInfo.status == 'Success' ? Colors.green : Colors.orange)),
                                if (backupInfo.notes != null && backupInfo.notes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text('Notes: ${backupInfo.notes}', style: Theme.of(context).textTheme.bodySmall),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.restore_page_outlined, size: 18),
                                      label: const Text('Restore'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
                                      onPressed: backupController.isLoading ? null : () => _performRestore(backupController, backupInfo),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
                                      onPressed: backupController.isLoading ? null : () => _performDelete(backupController, backupInfo),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );

    return MainLayoutScaffold(
      title: 'Backup & Restore',
      appBarActions: [
        if (backupController.backupHistory.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade300),
            tooltip: 'Clear All Backup History & Files',
            onPressed: backupController.isLoading ? null : () => _performClearAll(backupController),
          )
      ],
      body: screenBody,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
