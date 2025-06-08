import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/shared/widgets/app_drawer.dart';

// Import all controllers that might be needed by the screens navigated to,
// as AppDrawer navigates via MaterialPageRoute which will build the screens.
// These providers are needed for the screens themselves to initialize without error during the test.
import 'package:workshop_management_app/modules/employees/controllers/employee_controller.dart';
import 'package:workshop_management_app/modules/orders/controllers/order_controller.dart';
import 'package:workshop_management_app/modules/purchases/controllers/purchase_controller.dart';
import 'package:workshop_management_app/modules/inventory/controllers/inventory_controller.dart';
import 'package:workshop_management_app/modules/parts/controllers/part_controller.dart';
import 'package:workshop_management_app/modules/reports/controllers/report_controller.dart';
import 'package:workshop_management_app/modules/backup/controllers/backup_controller.dart';

// Import target screens to check for their presence after navigation
import 'package:workshop_management_app/modules/employees/views/employee_list_screen.dart';
import 'package:workshop_management_app/modules/orders/views/customer_list_screen.dart';
import 'package:workshop_management_app/modules/orders/views/sales_order_list_screen.dart';
import 'package:workshop_management_app/modules/purchases/views/supplier_list_screen.dart';
import 'package:workshop_management_app/modules/purchases/views/purchase_invoice_list_screen.dart';
import 'package:workshop_management_app/modules/inventory/views/inventory_list_screen.dart';
import 'package:workshop_management_app/modules/parts/views/part_list_screen.dart';
import 'package:workshop_management_app/modules/reports/views/report_dashboard_screen.dart';
import 'package:workshop_management_app/modules/backup/views/backup_settings_screen.dart';


Widget createTestableAppDrawer() {
  return MultiProvider(
    providers: [
      // Provide all necessary controllers that the navigated-to screens might depend on
      ChangeNotifierProvider(create: (_) => EmployeeController()),
      ChangeNotifierProvider(create: (_) => OrderController()),
      ChangeNotifierProvider(create: (_) => PurchaseController()),
      ChangeNotifierProvider(create: (_) => InventoryController()),
      ChangeNotifierProvider(create: (_) => PartController()),
      ChangeNotifierProvider(create: (_) => ReportController()),
      ChangeNotifierProvider(create: (_) => BackupController()),
    ],
    child: MaterialApp(
      home: Scaffold(
        drawer: AppDrawer(),
        // Dummy body, AppBar needed to host the drawer for testing
        appBar: AppBar(title: Text("Test Home")),
        body: Container(),
      ),
    ),
  );
}

void main() {
  testWidgets('AppDrawer contains all navigation items and navigates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableAppDrawer());

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Workshop Manager'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Employees'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Customers'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Sales Orders'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Suppliers'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Purchase Invoices'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Inventory'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Parts & Assemblies'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Reports'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Backup & Restore'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Customers'));
    await tester.pumpAndSettle();

    // CustomerListScreen uses MainLayoutScaffold which sets AppBar title to 'Customers'
    expect(find.text('Customers'), findsWidgets); // Finds AppBar title and potentially other instances
    expect(find.byType(CustomerListScreen), findsOneWidget);

    final ScaffoldState newState = tester.firstState(find.byType(Scaffold));
    newState.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Reports'));
    await tester.pumpAndSettle();
    // ReportDashboardScreen uses MainLayoutScaffold which sets AppBar title
    expect(find.text('Reports Dashboard'), findsWidgets);
    expect(find.byType(ReportDashboardScreen), findsOneWidget);
  });
}
