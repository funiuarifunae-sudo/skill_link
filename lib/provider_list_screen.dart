import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'provider_detail_screen.dart';

class ProviderListScreen extends StatelessWidget {
  final String category;

  const ProviderListScreen({
    super.key,
    required this.category,
  });

  String availabilityLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available Now';
      case 'busy':
        return 'Busy';
      default:
        return 'Offline';
    }
  }

  Color availabilityColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final providersStream = FirebaseFirestore.instance
        .collection('providerProfiles')
        .where('category', isEqualTo: category)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: providersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load providers: ${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final providers = snapshot.data?.docs ?? [];

          if (providers.isEmpty) {
            return Center(
              child: Text(
                'No $category providers are available yet',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final document = providers[index];
              final provider = document.data();

              final name =
                  provider['businessName'] as String? ??
                      'Unnamed provider';
              final location =
                  provider['location'] as String? ??
                      'Location unavailable';
              final priceRange =
                  provider['priceRange'] as String? ??
                      'Price unavailable';
              final description =
                  provider['description'] as String? ??
                      'No description';
              final rating =
                  (provider['averageRating'] as num?)?.toDouble() ??
                      0.0;
              final availabilityStatus =
                  provider['availabilityStatus'] as String? ??
                      'offline';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: availabilityColor(
                              availabilityStatus,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            availabilityLabel(
                              availabilityStatus,
                            ),
                            style: TextStyle(
                              color: availabilityColor(
                                availabilityStatus,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('$location\n$priceRange'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderDetailScreen(
                          providerId: document.id,
                          name: name,
                          specialty: category,
                          rating: rating.toStringAsFixed(1),
                          description: description,
                          location: location,
                          priceRange: priceRange,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}