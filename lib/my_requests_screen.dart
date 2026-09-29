import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'review_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in again'),
        ),
      );
    }

    final requestsStream = FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('customerId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: requestsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load requests: ${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text('You have not submitted any requests'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final document = requests[index];
              final request = document.data();

              final providerId =
                  request['providerId'] as String? ?? '';
              final providerName =
                  request['providerName'] as String? ?? 'Unknown provider';
              final specialty =
                  request['specialty'] as String? ?? 'Service';
              final status =
                  request['status'] as String? ?? 'Pending';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Service: $specialty'),
                      const SizedBox(height: 8),
                      Text('Status: $status'),
                      if (status == 'Completed') ...[
                        const SizedBox(height: 16),
                        StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('reviews')
                              .doc(document.id)
                              .snapshots(),
                          builder: (context, reviewSnapshot) {
                            if (reviewSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            if (reviewSnapshot.data?.exists == true) {
                              return const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Review submitted'),
                                ],
                              );
                            }

                            return ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReviewScreen(
                                      requestId: document.id,
                                      providerId: providerId,
                                      providerName: providerName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.star),
                              label: const Text('Rate Service'),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}