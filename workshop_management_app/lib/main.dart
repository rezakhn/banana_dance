import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/employees/controllers/employee_controller.dart';
import 'modules/employees/views/employee_list_screen.dart';
import 'modules/purchases/controllers/purchase_controller.dart'; // Added this line
// import 'core/database_service.dart';

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
        ChangeNotifierProvider( // Added this provider
          create: (_) => PurchaseController(),
        ),
        // TODO: Add other controllers here (InventoryController, etc.)
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
