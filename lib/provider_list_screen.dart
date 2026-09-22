import 'package:flutter/material.dart';
import 'provider_detail_screen.dart';

class ProviderListScreen extends StatelessWidget {
  final String category;

  const ProviderListScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('Naledi Tutoring Services'),
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ProviderDetailScreen(
        name: 'Naledi Tutoring Services',
        specialty: 'Mathematics and Science',
        rating: '4.8',
      ),
    ),
  );
},
              subtitle: Text(
                'Mathematics and Science\nRating: 4.8',
              ),
              isThreeLine: true,
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('Thabo Academic Support'),
              subtitle: Text(
                'English and Business Studies\nRating: 4.6',
              ),
              isThreeLine: true,
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('Lerato Learning Centre'),
              subtitle: Text(
                'Primary School Subjects\nRating: 4.9',
              ),
              isThreeLine: true,
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}