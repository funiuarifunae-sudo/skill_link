import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'provider_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const List<String> defaultCategories = [
    'Tutors',
    'Electricians',
    'Plumbers',
    'Cleaning Services',
    'Mechanics',
    'Photographers',
    'Gardening',
    'Beauty and Wellness',
    'Catering',
    'IT and Tech Support',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Tutors': Icons.school,
    'Electricians': Icons.electrical_services,
    'Plumbers': Icons.plumbing,
    'Cleaning Services': Icons.cleaning_services,
    'Mechanics': Icons.car_repair,
    'Photographers': Icons.camera_alt,
    'Gardening': Icons.yard,
    'Beauty and Wellness': Icons.spa,
    'Catering': Icons.restaurant,
    'IT and Tech Support': Icons.computer,
  };

  Set<String> categoriesForProvider(
    Map<String, dynamic> provider,
  ) {
    final categories = <String>{};

    final savedCategories =
        provider['serviceCategories'];

    if (savedCategories is List) {
      for (final category in savedCategories) {
        if (category is String &&
            category.trim().isNotEmpty) {
          categories.add(category.trim());
        }
      }
    }

    final services = provider['services'];

    if (services is List) {
      for (final service in services) {
        if (service is! Map) continue;

        final serviceData =
            Map<String, dynamic>.from(service);

        final category =
            serviceData['category'] as String? ?? '';

        if (category.trim().isNotEmpty) {
          categories.add(category.trim());
        }
      }
    }

    // Support provider profiles created before
    // multiple services were introduced.
    if (categories.isEmpty) {
      final originalCategory =
          provider['category'] as String? ?? '';

      if (originalCategory.trim().isNotEmpty) {
        categories.add(
          originalCategory.trim(),
        );
      }
    }

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final profilesStream =
        FirebaseFirestore.instance
            .collection('providerProfiles')
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Categories',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: profilesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load categories: '
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

          final profiles =
              snapshot.data?.docs ?? [];

          final providerCounts =
              <String, int>{};

          for (final profile in profiles) {
            final providerCategories =
                categoriesForProvider(
              profile.data(),
            );

            // A provider is counted only once in each
            // category, even if they added two services
            // with the same category.
            for (final category
                in providerCategories) {
              providerCounts[category] =
                  (providerCounts[category] ??
                          0) +
                      1;
            }
          }

          final allCategories = <String>{
            ...defaultCategories,
            ...providerCounts.keys,
          }.toList();

          final customCategories =
              allCategories
                  .where(
                    (category) =>
                        !defaultCategories
                            .contains(category),
                  )
                  .toList()
                ..sort();

          final displayedCategories = [
            ...defaultCategories,
            ...customCategories,
          ];

          return ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.explore,
                        size: 36,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Explore local services',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose a category to find '
                              'providers near you.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              ...displayedCategories.map(
                (category) {
                  final providerCount =
                      providerCounts[category] ??
                          0;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          categoryIcons[
                                  category] ??
                              Icons.work_outline,
                        ),
                      ),
                      title: Text(category),
                      subtitle: Text(
                        providerCount == 0
                            ? 'No providers yet'
                            : '$providerCount '
                                '${providerCount == 1 ? 'provider' : 'providers'}',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProviderListScreen(
                              category:
                                  category,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}