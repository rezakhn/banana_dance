import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers
import 'modules/employees/controllers/employee_controller.dart';
import 'modules/purchases/controllers/purchase_controller.dart';
import 'modules/parts/controllers/part_controller.dart';
import 'modules/orders/controllers/order_controller.dart';
import 'modules/inventory/controllers/inventory_controller.dart';
import 'modules/reports/controllers/report_controller.dart';
import 'modules/backup/controllers/backup_controller.dart';

// Entry Screen
import 'modules/employees/views/employee_list_screen.dart';

// Custom Theme
import 'shared/themes/app_theme.dart'; // Added import for AppTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EmployeeController()..fetchEmployees(),
        ),
        ChangeNotifierProvider(
          create: (_) => PurchaseController(),
        ),
        ChangeNotifierProvider(
          create: (_) => PartController(),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderController(),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportController(),
        ),
        ChangeNotifierProvider(
          create: (_) => BackupController(),
        ),
      ],
      child: MaterialApp(
        title: 'Workshop Management',
        // Apply the custom light theme
        theme: AppTheme.lightTheme,
        // Dark theme can be added later if needed:
        // darkTheme: AppTheme.darkTheme,
        // themeMode: ThemeMode.system, // Or allow user to choose

        home: const EmployeeListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
