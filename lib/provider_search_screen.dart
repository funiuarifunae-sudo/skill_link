import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'provider_detail_screen.dart';

class ProviderSearchScreen extends StatefulWidget {
  const ProviderSearchScreen({super.key});

  @override
  State<ProviderSearchScreen> createState() =>
      _ProviderSearchScreenState();
}

class _ProviderSearchScreenState
    extends State<ProviderSearchScreen> {
  final searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersStream = FirebaseFirestore.instance
        .collection('providerProfiles')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Services'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search providers or services',
                hintText: 'Example: tutor, plumber or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchText = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: providersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to search providers: ${snapshot.error}',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allProviders = snapshot.data?.docs ?? [];
                if (searchText.isEmpty) {
  return const Center(
    child: Text(
      'Enter a provider, service, or location to search',
    ),
  );
}

                final providers = allProviders.where((document) {
                  final data = document.data();

                  final businessName =
                      (data['businessName'] as String? ?? '')
                          .toLowerCase();
                  final category =
                      (data['category'] as String? ?? '')
                          .toLowerCase();
                  final location =
                      (data['location'] as String? ?? '')
                          .toLowerCase();
                  final description =
                      (data['description'] as String? ?? '')
                          .toLowerCase();

                  return businessName.contains(searchText) ||
                      category.contains(searchText) ||
                      location.contains(searchText) ||
                      description.contains(searchText);
                }).toList();

                if (providers.isEmpty) {
                  return const Center(
                    child: Text('No matching providers found'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final document = providers[index];
                    final provider = document.data();

                    final name =
                        provider['businessName'] as String? ??
                            'Unnamed provider';
                    final category =
                        provider['category'] as String? ??
                            'Service';
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
                        (provider['averageRating'] as num?)
                                ?.toDouble() ??
                            0.0;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          '$category\n$location',
                        ),
                        isThreeLine: true,
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProviderDetailScreen(
                                providerId: document.id,
                                name: name,
                                specialty: category,
                                rating:
                                    rating.toStringAsFixed(1),
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
          ),
        ],
      ),
    );
  }
}