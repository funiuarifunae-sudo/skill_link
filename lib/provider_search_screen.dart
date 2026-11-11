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

  List<Map<String, String>> servicesForProvider(
    Map<String, dynamic> provider,
  ) {
    final services = <Map<String, String>>[];

    final savedServices = provider['services'];

    if (savedServices is List) {
      for (final service in savedServices) {
        if (service is! Map) continue;

        final serviceData =
            Map<String, dynamic>.from(service);

        final category =
            serviceData['category'] as String? ?? '';

        if (category.trim().isEmpty) {
          continue;
        }

        services.add({
          'category': category.trim(),
          'description':
              serviceData['description']
                      as String? ??
                  'No description',
          'priceRange':
              serviceData['priceRange']
                      as String? ??
                  'Price unavailable',
        });
      }
    }

    // Support profiles created before multiple
    // service offerings were introduced.
    if (services.isEmpty) {
      final category =
          provider['category'] as String? ?? '';

      if (category.trim().isNotEmpty) {
        services.add({
          'category': category.trim(),
          'description':
              provider['description']
                      as String? ??
                  'No description',
          'priceRange':
              provider['priceRange']
                      as String? ??
                  'Price unavailable',
        });
      }
    }

    return services;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersStream =
        FirebaseFirestore.instance
            .collection('providerProfiles')
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Services'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              4,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText =
                      value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText:
                    'Search providers or services',
                hintText:
                    'Example: tutor, mechanic or location',
                prefixIcon:
                    const Icon(Icons.search),
                suffixIcon: searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchText = '';
                          });
                        },
                        icon: const Icon(
                          Icons.clear,
                        ),
                      ),
                border:
                    const OutlineInputBorder(),
              ),
            ),
          ),

          SwitchListTile(
            title: const Text(
              'Show available providers only',
            ),
            secondary: const Icon(
              Icons.online_prediction,
            ),
            value: availableOnly,
            onChanged: (value) {
              setState(() {
                availableOnly = value;
              });
            },
          ),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: providersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to search providers: '
                      '${snapshot.error}',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (searchText.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(24),
                      child: Text(
                        'Enter a provider, service, '
                        'description, price or location '
                        'to search',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                final results =
                    <_ServiceSearchResult>[];

                for (final document
                    in documents) {
                  final provider =
                      document.data();

                  final status =
                      provider[
                                  'availabilityStatus']
                              as String? ??
                          'offline';

                  if (availableOnly &&
                      status != 'available') {
                    continue;
                  }

                  final businessName =
                      (provider['businessName']
                                  as String? ??
                              '')
                          .toLowerCase();

                  final location =
                      (provider['location']
                                  as String? ??
                              '')
                          .toLowerCase();

                  final providerMatches =
                      businessName.contains(
                            searchText,
                          ) ||
                          location.contains(
                            searchText,
                          );

                  final services =
                      servicesForProvider(
                    provider,
                  );

                  for (final service
                      in services) {
                    final category =
                        (service['category'] ?? '')
                            .toLowerCase();

                    final description =
                        (service['description'] ??
                                '')
                            .toLowerCase();

                    final priceRange =
                        (service['priceRange'] ??
                                '')
                            .toLowerCase();

                    final serviceMatches =
                        category.contains(
                              searchText,
                            ) ||
                            description.contains(
                              searchText,
                            ) ||
                            priceRange.contains(
                              searchText,
                            );

                    if (providerMatches ||
                        serviceMatches) {
                      results.add(
                        _ServiceSearchResult(
                          document: document,
                          provider: provider,
                          service: service,
                        ),
                      );
                    }
                  }
                }

                if (results.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching services found',
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: results.length,
                  itemBuilder:
                      (context, index) {
                    final result =
                        results[index];

                    final document =
                        result.document;

                    final provider =
                        result.provider;

                    final service =
                        result.service;

                    final name =
                        provider['businessName']
                                as String? ??
                            'Unnamed provider';

                    final category =
                        service['category'] ??
                            'Service';

                    final description =
                        service['description'] ??
                            'No description';

                    final priceRange =
                        service['priceRange'] ??
                            'Price unavailable';

                    final location =
                        provider['location']
                                as String? ??
                            'Location unavailable';

                    final rating =
                        (provider[
                                    'averageRating']
                                as num?)
                            ?.toDouble() ??
                            0.0;

                    final availabilityStatus =
                        provider[
                                    'availabilityStatus']
                                as String? ??
                            'offline';

                    return Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child:
                              Icon(Icons.person),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const SizedBox(
                              height: 4,
                            ),

                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color:
                                      availabilityColor(
                                    availabilityStatus,
                                  ),
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                Text(
                                  availabilityLabel(
                                    availabilityStatus,
                                  ),
                                  style: TextStyle(
                                    color:
                                        availabilityColor(
                                      availabilityStatus,
                                    ),
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              category,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(location),

                            Text(
                              priceRange,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProviderDetailScreen(
                                providerId:
                                    document.id,
                                name: name,
                                specialty:
                                    category,
                                rating: rating
                                    .toStringAsFixed(
                                      1,
                                    ),
                                description:
                                    description,
                                location:
                                    location,
                                priceRange:
                                    priceRange,
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

class _ServiceSearchResult {
  final QueryDocumentSnapshot<
      Map<String, dynamic>> document;

  final Map<String, dynamic> provider;
  final Map<String, String> service;

  const _ServiceSearchResult({
    required this.document,
    required this.provider,
    required this.service,
  });
}