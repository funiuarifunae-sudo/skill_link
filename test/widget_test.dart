import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_link/categories_screen.dart';

void main() {
  testWidgets(
    'Service categories are displayed',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoriesScreen(),
        ),
      );

      expect(find.text('Service Categories'), findsOneWidget);
      expect(find.text('Tutors'), findsOneWidget);
      expect(find.text('Electricians'), findsOneWidget);
      expect(find.text('Plumbers'), findsOneWidget);
      expect(find.text('Cleaning Services'), findsOneWidget);
    },
  );
}