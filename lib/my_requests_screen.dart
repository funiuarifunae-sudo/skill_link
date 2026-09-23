import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your requests'),
        ),
      );
    }

    final requestStream = FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('customerId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: requestStream,
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
              child: Text('You have not submitted any requests yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data();

              final providerName =
                  request['providerName'] as String? ?? 'Unknown provider';
              final specialty =
                  request['specialty'] as String? ?? 'Unknown service';
              final status =
                  request['status'] as String? ?? 'Pending';
              final createdAt = request['createdAt'] as Timestamp?;

              final submittedText = createdAt == null
                  ? 'Submitted recently'
                  : 'Submitted: '
                      '${createdAt.toDate().toLocal().toString().split('.').first}';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.handyman),
                  ),
                  title: Text(providerName),
                  subtitle: Text(
                    '$specialty\n$status\n$submittedText',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}