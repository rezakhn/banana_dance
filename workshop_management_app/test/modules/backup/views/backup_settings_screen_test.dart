import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/backup/controllers/backup_controller.dart';
import 'package:workshop_management_app/modules/backup/views/backup_settings_screen.dart';
import 'package:workshop_management_app/modules/backup/models/backup_info.dart';

// Mock BackupController
class MockBackupController extends ChangeNotifier implements BackupController {
  List<BackupInfo> _history = [];
  bool _loading = false;
  String? _message;
  bool _isErr = false;

  @override List<BackupInfo> get backupHistory => _history;
  @override bool get isLoading => _loading;
  @override String? get operationMessage => _message;
  @override bool get isError => _isErr;

  @override Future<void> fetchBackupHistory() async { /* Mock */ }
  @override Future<void> createNewBackup({String? notes}) async {
    _loading = true; notifyListeners();
    await Future.delayed(Duration(milliseconds:10));
    _message = "Mock Backup Created!"; _isErr = false;
    _history.add(BackupInfo(id: _history.length + 1, backupDate: DateTime.now(), filePath: "/mock/backup${_history.length + 1}.db", status: "Success"));
    _loading = false; notifyListeners();
  }
  @override Future<void> restoreFromBackup(BackupInfo backupToRestore) async { /* Mock */ }
  @override Future<void> deleteBackup(BackupInfo backupToDelete) async { /* Mock */ }
  @override Future<void> clearAllBackupHistoryAndFiles() async { /* Mock */ }

  // This method is private in actual controller, but we need to satisfy the interface for the mock.
  // Or, don't implement the full interface but just the parts used by the UI.
  // For simplicity in this mock, we'll just provide it.
  Future<bool> _requestStoragePermission() async => true;


  // Test setup methods
  void setTestHistory(List<BackupInfo> history) { _history = history; notifyListeners(); }
  void setLoading(bool val) { _loading = val; notifyListeners(); }
  void setMessage(String msg, bool isErr) { _message = msg; _isErr = isErr; notifyListeners(); }
}


void main() {
  late MockBackupController mockController;

  setUp(() {
    mockController = MockBackupController();
  });

  Widget buildTestableWidget() {
    return ChangeNotifierProvider<BackupController>.value(
      value: mockController,
      child: MaterialApp(home: BackupSettingsScreen()),
    );
  }

  testWidgets('BackupSettingsScreen displays create backup button and history list', (WidgetTester tester) async {
    final backup1 = BackupInfo(id: 1, backupDate: DateTime.now().subtract(Duration(days:1)), filePath: "/path/backup1.db", status: "Success", fileSize: 10240);
    final backup2 = BackupInfo(id: 2, backupDate: DateTime.now(), filePath: "/path/backup2.db", status: "Success", fileSize: 20480);
    mockController.setTestHistory([backup1, backup2]);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Create New Backup Now'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Notes field
    expect(find.textContaining('Backup History (2 entries)'), findsOneWidget);
    expect(find.textContaining('backup1.db'), findsOneWidget);
    expect(find.textContaining('backup2.db'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Restore'), findsNWidgets(2));
    expect(find.widgetWithText(TextButton, 'Delete'), findsNWidgets(2));
  });

  testWidgets('Create New Backup button calls controller method', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create New Backup Now'));
    await tester.pumpAndSettle(); // For controller state changes

    expect(mockController.operationMessage, "Mock Backup Created!");
    // The mock adds an item to history, so we should find 1 item (the new one)
    // or more if the mock was designed to append to existing test history.
    // Based on the mock: it adds one with id = _history.length + 1
    expect(find.textContaining('backup1.db'), findsOneWidget);
  });

  testWidgets('Restore button shows confirmation dialog (mocked)', (WidgetTester tester) async {
    final backup1 = BackupInfo(id: 1, backupDate: DateTime.now(), filePath: "/path/b1.db");
    mockController.setTestHistory([backup1]);
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Restore').first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, 'Confirm Restore'), findsOneWidget);
    expect(find.textContaining('OVERWRITE all current data'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
  });

}
