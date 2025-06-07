import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:workshop_management_app/modules/parts/models/assembly_order.dart';
import 'package:workshop_management_app/modules/parts/widgets/assembly_order_card.dart';

void main() {
  final testDate = DateTime.now();
  final testOrder = AssemblyOrder(id:1, partId: 1, quantityToProduce: 5, date: testDate, status: 'Pending');
  Widget buildTestableWidget(AssemblyOrder o, String name, {VoidCallback? onTap, VoidCallback? onDelete, VoidCallback? onLongPress}) {
    return MaterialApp(home: Scaffold(body: AssemblyOrderCard(order: o, assemblyName: name, onTap: onTap, onDelete: onDelete, onLongPress: onLongPress)));
  }
  // ... tests ...
   testWidgets('AssemblyOrderCard displays details', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testOrder, 'Test Assembly'));
    expect(find.textContaining('Assemble: Test Assembly (Order ID: 1)'), findsOneWidget);
    expect(find.textContaining('Qty: 5'), findsOneWidget);
    expect(find.textContaining('Status: Pending'), findsOneWidget);
  });
}
