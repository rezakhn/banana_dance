import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/employees/controllers/employee_controller.dart';
import 'modules/employees/views/employee_list_screen.dart';
import 'modules/purchases/controllers/purchase_controller.dart';
import 'modules/parts/controllers/part_controller.dart'; // Added this line

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
        ChangeNotifierProvider( // Added this provider for PartController
          create: (_) => PartController(),
        ),
        // TODO: Add other controllers here (InventoryController for full inventory view, Sales, Reports etc.)
      ],
      child: MaterialApp(
        title: 'Workshop Management',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const EmployeeListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
