import 'package:flutter/material.dart';
import 'provider_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Categories'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.school),
              title: Text('Tutors'),
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ProviderListScreen(
        category: 'Tutors',
      ),
    ),
  );
},
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.electrical_services),
              title: Text('Electricians'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.plumbing),
              title: Text('Plumbers'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.cleaning_services),
              title: Text('Cleaning Services'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}