import 'package:flutter_test/flutter_test.dart';
import 'package:skill_link/categories_screen.dart';

void main() {
  test(
    'Default service categories include key local services',
    () {
      expect(
        CategoriesScreen.defaultCategories,
        contains('Tutors'),
      );

      expect(
        CategoriesScreen.defaultCategories,
        contains('Electricians'),
      );

      expect(
        CategoriesScreen.defaultCategories,
        contains('Plumbers'),
      );

      expect(
        CategoriesScreen.defaultCategories,
        contains('Cleaning Services'),
      );

      expect(
        CategoriesScreen.defaultCategories,
        contains('Mechanics'),
      );

      expect(
        CategoriesScreen.defaultCategories,
        contains('Photographers'),
      );

      expect(
        CategoriesScreen.defaultCategories.length,
        greaterThanOrEqualTo(10),
      );

      expect(
        CategoriesScreen.categoryIcons['Mechanics'],
        isNotNull,
      );

      expect(
        CategoriesScreen.categoryIcons['Photographers'],
        isNotNull,
      );
    },
  );
}