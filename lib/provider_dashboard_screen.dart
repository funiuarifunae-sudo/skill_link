import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'incoming_requests_screen.dart';
import 'manage_services_screen.dart';
import 'provider_profile_form_screen.dart';
import 'provider_reviews_screen.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  Future<void> updateAvailability(
    BuildContext context,
    String providerId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('providerProfiles')
          .doc(providerId)
          .set({
        'availabilityStatus': status,
        'availabilityUpdatedAt':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Availability changed to '
            '${availabilityLabel(status)}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update availability: $error',
          ),
        ),
      );
    }
  }

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
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Provider Dashboard',
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () async {
              await FirebaseAuth.instance
                  .signOut();

              if (!context.mounted) return;

              Navigator.of(context)
                  .pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.business_center,
            size: 72,
          ),

          const SizedBox(height: 16),

          Text(
            'Welcome, Service Provider',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 8),

          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          if (user != null)
            StreamBuilder<
                DocumentSnapshot<
                    Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(
                    'providerProfiles',
                  )
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data();

                final currentStatus =
                    data?['availabilityStatus']
                            as String? ??
                        'offline';

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Availability',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 14,
                              color:
                                  availabilityColor(
                                currentStatus,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              availabilityLabel(
                                currentStatus,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text(
                                'Available Now',
                              ),
                              selected:
                                  currentStatus ==
                                      'available',
                              onSelected: (_) {
                                updateAvailability(
                                  context,
                                  user.uid,
                                  'available',
                                );
                              },
                            ),

                            ChoiceChip(
                              label:
                                  const Text('Busy'),
                              selected:
                                  currentStatus ==
                                      'busy',
                              onSelected: (_) {
                                updateAvailability(
                                  context,
                                  user.uid,
                                  'busy',
                                );
                              },
                            ),

                            ChoiceChip(
                              label:
                                  const Text('Offline'),
                              selected:
                                  currentStatus ==
                                      'offline',
                              onSelected: (_) {
                                updateAvailability(
                                  context,
                                  user.uid,
                                  'offline',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.storefront,
              ),
              title: const Text(
                'My Business Profile',
              ),
              subtitle: const Text(
                'Update your business, contact '
                'and location details',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProviderProfileFormScreen(),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.design_services,
              ),
              title: const Text(
                'Manage Services',
              ),
              subtitle: const Text(
                'Add different descriptions and '
                'prices for each service',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ManageServicesScreen(),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.inbox,
              ),
              title: const Text(
                'Incoming Requests',
              ),
              subtitle: const Text(
                'View requests submitted '
                'by customers',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const IncomingRequestsScreen(),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.star,
              ),
              title: const Text(
                'Ratings and Reviews',
              ),
              subtitle: const Text(
                'View feedback from customers',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProviderReviewsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}