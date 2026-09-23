import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderDetailScreen extends StatelessWidget {
  final String name;
  final String specialty;
  final String rating;

  const ProviderDetailScreen({
    super.key,
    required this.name,
    required this.specialty,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 48,
              child: Icon(
                Icons.person,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              specialty,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Rating: $rating',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Experienced tutor offering friendly and reliable '
                  'academic support for learners in the local community.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.location_on),
                title: Text('Central Area'),
                subtitle: Text('Available for local and online lessons'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in before requesting a service'),
      ),
    );
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection('serviceRequests')
        .add({
      'customerId': user.uid,
      'customerEmail': user.email,
      'providerName': name,
      'specialty': specialty,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service request submitted'),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request failed: $error'),
      ),
    );
  }
},
              child: const Text('Request Service'),
            ),
          ],
        ),
      ),
    );
  }
}