import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProviderDetailScreen extends StatelessWidget {
  final String providerId;
  final String name;
  final String specialty;
  final String rating;
  final String description;
  final String location;
  final String priceRange;

  const ProviderDetailScreen({
    super.key,
    required this.providerId,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.description,
    required this.location,
    required this.priceRange,
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
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: FirebaseFirestore.instance
      .collection('reviews')
      .where('providerId', isEqualTo: providerId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text(
        'Loading rating...',
        textAlign: TextAlign.center,
      );
    }

    final reviews = snapshot.data?.docs ?? [];

    if (reviews.isEmpty) {
      return const Text(
        'No ratings yet',
        textAlign: TextAlign.center,
      );
    }

    double total = 0;

    for (final review in reviews) {
      total +=
          (review.data()['rating'] as num?)?.toDouble() ?? 0.0;
    }

    final average = total / reviews.length;

    return Text(
      'Rating: ${average.toStringAsFixed(1)} '
      '(${reviews.length} review(s))',
      textAlign: TextAlign.center,
    );
  },
),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(description),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(location),
                subtitle: const Text('Service area'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments),
                title: Text(priceRange),
                subtitle: const Text('Price range'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please log in before requesting a service',
                      ),
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
                    'providerId': providerId,
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