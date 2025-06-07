import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/modules/parts/models/part.dart';
import 'package:workshop_management_app/modules/parts/widgets/part_card.dart';

void main() {
  final testPartRaw = Part(id: 1, name: 'Raw Material 1', isAssembly: false);
  final testPartAssembly = Part(id: 2, name: 'Assembly Alpha', isAssembly: true);

  Widget buildTestableWidget(Part part, {VoidCallback? onTap, VoidCallback? onDelete}) {
    return MaterialApp(home: Scaffold(body: PartCard(part: part, onTap: onTap, onDelete: onDelete)));
  }

  testWidgets('PartCard displays name and correct type for Raw Material', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testPartRaw));
    expect(find.text('Raw Material 1'), findsOneWidget);
    expect(find.text('Type: Component/Raw Material'), findsOneWidget);
  });

  testWidgets('PartCard displays name and correct type for Assembly', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testPartAssembly));
    expect(find.text('Assembly Alpha'), findsOneWidget);
    expect(find.text('Type: Assembly'), findsOneWidget);
  });

  testWidgets('PartCard calls onTap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(buildTestableWidget(testPartRaw, onTap: () => tapped = true));
    await tester.tap(find.byType(PartCard));
    expect(tapped, isTrue);
  });

   testWidgets('PartCard calls onDelete', (WidgetTester tester) async {
    bool deleted = false;
    await tester.pumpWidget(buildTestableWidget(testPartRaw, onDelete: () => deleted = true));
    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete));
    expect(deleted, isTrue);
  });
}
