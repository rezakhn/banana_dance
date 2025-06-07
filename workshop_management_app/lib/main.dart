import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/employees/controllers/employee_controller.dart';
import 'modules/employees/views/employee_list_screen.dart';
import 'modules/purchases/controllers/purchase_controller.dart';
import 'modules/parts/controllers/part_controller.dart';
import 'modules/orders/controllers/order_controller.dart';
import 'modules/inventory/controllers/inventory_controller.dart'; // Added

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
        ChangeNotifierProvider( // Added InventoryController
          create: (_) => InventoryController(),
        ),
        // TODO: Add other controllers here (Reports etc.)
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
