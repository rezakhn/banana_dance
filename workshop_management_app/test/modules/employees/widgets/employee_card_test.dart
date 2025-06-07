import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/modules/employees/models/employee.dart';
import 'package:workshop_management_app/modules/employees/widgets/employee_card.dart';

void main() {
  testWidgets('EmployeeCard displays employee name and pay type', (WidgetTester tester) async {
    final employee = Employee(
      name: 'Test Employee',
      payType: 'hourly',
      hourlyRate: 15,
      overtimeRate: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeCard(employee: employee),
        ),
      ),
    );

    // Verify that the employee's name is displayed.
    expect(find.text('Test Employee'), findsOneWidget);
    // Verify that the pay type is displayed.
    expect(find.textContaining('Pay Type: hourly'), findsOneWidget);
  });

  testWidgets('EmployeeCard onTap callback is called', (WidgetTester tester) async {
    bool tapped = false;
    final employee = Employee(name: 'Tap Test', payType: 'daily', dailyRate: 100, overtimeRate: 10);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeCard(
            employee: employee,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EmployeeCard));
    await tester.pump(); // Rebuild the widget after the tap.

    expect(tapped, isTrue);
  });

  // Add more tests for onDelete, onEdit, onLongPress if needed
}
