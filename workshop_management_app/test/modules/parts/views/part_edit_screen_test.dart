import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/parts/controllers/part_controller.dart';
import 'package:workshop_management_app/modules/parts/views/part_edit_screen.dart';
import 'package:workshop_management_app/modules/parts/models/part.dart';

void main() {
  Widget buildTestableWidget({Part? part}) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PartController())],
      child: MaterialApp(home: PartEditScreen(part: part)),
    );
  }

  testWidgets('PartEditScreen shows name field and assembly switch', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    expect(find.widgetWithText(TextFormField, 'Part Name'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('PartEditScreen shows component UI when isAssembly is true', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(part: Part(id:1, name:"Test", isAssembly:true)));
    await tester.pumpAndSettle(); // For any post-frame callbacks
    // The switch itself needs to be found and tapped, or initial value set.
    // For this, we pass an assembly part.
    expect(find.text('Components for this Assembly:'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Add Component'), findsOneWidget);
  });
}
