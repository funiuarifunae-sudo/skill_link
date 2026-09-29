import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key});

  Future<void> updateStatus(
    BuildContext context,
    String requestId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('serviceRequests')
          .doc(requestId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request marked as $newStatus'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update request: $error'),
        ),
      );
    }
  }

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
        .where('providerId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
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
              child: Text('No incoming requests yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final document = requests[index];
              final request = document.data();

              final customerEmail =
                  request['customerEmail'] as String? ?? 'Unknown customer';
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
                        specialty,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Customer: $customerEmail'),
                      const SizedBox(height: 8),
                      Text('Status: $status'),
                      const SizedBox(height: 16),
                      if (status == 'Pending')
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                updateStatus(
                                  context,
                                  document.id,
                                  'Accepted',
                                );
                              },
                              child: const Text('Accept'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                updateStatus(
                                  context,
                                  document.id,
                                  'Declined',
                                );
                              },
                              child: const Text('Decline'),
                            ),
                          ],
                        ),
                      if (status == 'Accepted')
                        ElevatedButton(
                          onPressed: () {
                            updateStatus(
                              context,
                              document.id,
                              'Completed',
                            );
                          },
                          child: const Text('Mark Completed'),
                        ),
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