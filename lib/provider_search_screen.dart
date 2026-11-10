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
  bool availableOnly = false;

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
          SwitchListTile(
            title: const Text('Show available providers only'),
            secondary: const Icon(Icons.online_prediction),
            value: availableOnly,
            onChanged: (value) {
              setState(() {
                availableOnly = value;
              });
            },
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
                  final status =
                      data['availabilityStatus'] as String? ??
                          'offline';

                  final matchesSearch =
                      businessName.contains(searchText) ||
                          category.contains(searchText) ||
                          location.contains(searchText) ||
                          description.contains(searchText);

                  final matchesAvailability =
                      !availableOnly || status == 'available';

                  return matchesSearch && matchesAvailability;
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                            Text('$category\n$location'),
                          ],
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