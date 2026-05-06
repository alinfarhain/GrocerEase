// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:grocereasetest/main.dart';

void main() {
  testWidgets('App loads and shows grocery list', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GroceryApp());

    // Verify that the grocery list header is present.
    expect(find.text('Grocery List'), findsOneWidget);
    
    // Verify that some initial items are visible
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('Bell Peppers'), findsOneWidget);
  });
}
