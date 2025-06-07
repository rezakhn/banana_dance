import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/employees/controllers/employee_controller.dart';
import 'modules/employees/views/employee_list_screen.dart';
// import 'core/database_service.dart'; // Import if you need to initialize db early, though controller does it

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // If you need to perform any async operations before runApp, do them here.
  // For example, initializing the database if not handled by the first controller.
  // final dbService = DatabaseService();
  // await dbService.database; // Ensures DB is created if not already

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EmployeeController()..fetchEmployees(), // Initialize and fetch employees
        ),
        // TODO: Add other controllers here (PurchaseController, InventoryController, etc.)
      ],
      child: MaterialApp(
        title: 'Workshop Management',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // TODO: Define more theme details in shared/themes/app_theme.dart later
        ),
        home: const EmployeeListScreen(), // Start with EmployeeListScreen
        debugShowCheckedModeBanner: false,
        // TODO: Define routes for navigation later
        // routes: {
        //   '/': (context) => const DashboardScreen(), // Example
        //   '/employees': (context) => const EmployeeListScreen(),
        // },
      ),
    );
  }
}
