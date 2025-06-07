import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/modules/parts/models/product.dart';
import 'package:workshop_management_app/modules/parts/widgets/product_card.dart';

void main() {
  final testProduct = Product(id:1, name: 'Finished Product X');
  Widget buildTestableWidget(Product p, {VoidCallback? onTap, VoidCallback? onDelete}) {
    return MaterialApp(home: Scaffold(body: ProductCard(product: p, onTap: onTap, onDelete: onDelete)));
  }
  // ... tests similar to PartCard ...
  testWidgets('ProductCard displays name', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testProduct));
    expect(find.text('Finished Product X'), findsOneWidget);
  });
}
