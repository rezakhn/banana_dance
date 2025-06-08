import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart';
import 'package:workshop_management_app/shared/widgets/app_drawer.dart'; // To check if AppDrawer is used

// Need to provide controllers for AppDrawer's navigation targets if they are built in test
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/employees/controllers/employee_controller.dart';
import 'package:workshop_management_app/modules/orders/controllers/order_controller.dart';
import 'package:workshop_management_app/modules/purchases/controllers/purchase_controller.dart';
import 'package:workshop_management_app/modules/inventory/controllers/inventory_controller.dart';
import 'package:workshop_management_app/modules/parts/controllers/part_controller.dart';
import 'package:workshop_management_app/modules/reports/controllers/report_controller.dart';
import 'package:workshop_management_app/modules/backup/controllers/backup_controller.dart';


Widget createTestableMainLayoutScaffold({
  required String title,
  required Widget body,
  List<Widget>? appBarActions,
  Widget? floatingActionButton,
}) {
   return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => EmployeeController()),
      ChangeNotifierProvider(create: (_) => OrderController()),
      ChangeNotifierProvider(create: (_) => PurchaseController()),
      ChangeNotifierProvider(create: (_) => InventoryController()),
      ChangeNotifierProvider(create: (_) => PartController()),
      ChangeNotifierProvider(create: (_) => ReportController()),
      ChangeNotifierProvider(create: (_) => BackupController()),
    ],
    child: MaterialApp(
      home: MainLayoutScaffold(
        title: title,
        body: body,
        appBarActions: appBarActions,
        floatingActionButton: floatingActionButton,
      ),
    ),
  );
}


void main() {
  testWidgets('MainLayoutScaffold displays title, body, and AppDrawer', (WidgetTester tester) async {
    const testTitle = 'Test Screen Title';
    const testBodyKey = Key('testBody');
    final testBody = Container(key: testBodyKey, child: Text('Test Body Content'));

    await tester.pumpWidget(createTestableMainLayoutScaffold(title: testTitle, body: testBody));

    // Verify AppBar with title
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text(testTitle), findsOneWidget);

    // Verify Drawer (which should be AppDrawer)
    // Open the drawer to confirm its presence and type
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();
    expect(find.byType(AppDrawer), findsOneWidget);
    // Close drawer
    // Ensure context is valid for Navigator.pop
    if (Navigator.of(state.context).canPop()) {
      Navigator.of(state.context).pop();
    }
    await tester.pumpAndSettle();


    // Verify body content
    expect(find.byKey(testBodyKey), findsOneWidget);
    expect(find.text('Test Body Content'), findsOneWidget);
  });

  testWidgets('MainLayoutScaffold displays appBarActions', (WidgetTester tester) async {
    const actionIconKey = Key('actionIcon');
    final testActions = [IconButton(key: actionIconKey, icon: Icon(Icons.add), onPressed: () {})];

    await tester.pumpWidget(createTestableMainLayoutScaffold(title: 'Actions Test', body: Container(), appBarActions: testActions));

    expect(find.byKey(actionIconKey), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('MainLayoutScaffold displays floatingActionButton', (WidgetTester tester) async {
    const fabKey = Key('fab');
    final testFab = FloatingActionButton(key: fabKey, onPressed: () {}, child: Icon(Icons.edit));

    await tester.pumpWidget(createTestableMainLayoutScaffold(title: 'FAB Test', body: Container(), floatingActionButton: testFab));

    expect(find.byKey(fabKey), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
