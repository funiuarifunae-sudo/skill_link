import 'package:flutter/material.dart';

import 'provider_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'name': 'Tutors',
        'icon': Icons.school,
      },
      {
        'name': 'Electricians',
        'icon': Icons.electrical_services,
      },
      {
        'name': 'Plumbers',
        'icon': Icons.plumbing,
      },
      {
        'name': 'Cleaning Services',
        'icon': Icons.cleaning_services,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Categories'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryName = category['name'] as String;
          final categoryIcon = category['icon'] as IconData;

          return Card(
            child: ListTile(
              leading: Icon(categoryIcon),
              title: Text(categoryName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderListScreen(
                      category: categoryName,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}