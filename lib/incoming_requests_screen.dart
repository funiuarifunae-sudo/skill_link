import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request marked as $newStatus',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update request: $error',
          ),
        ),
      );
    }
  }

  Future<void> emailCustomer(
    BuildContext context, {
    required String customerEmail,
    required String specialty,
  }) async {
    if (customerEmail.isEmpty ||
        customerEmail == 'Unknown customer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Customer email is unavailable',
          ),
        ),
      );
      return;
    }

    final emailUrl = Uri(
      scheme: 'mailto',
      path: customerEmail,
      queryParameters: {
        'subject':
            'SkillLink: $specialty request',
        'body':
            'Hi,\n\nI am contacting you about '
                'your $specialty request on SkillLink.\n\n',
      },
    );

    final opened = await launchUrl(
      emailUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open an email application',
          ),
        ),
      );
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in again'),
        ),
      );
    }

    final requestsStream =
        FirebaseFirestore.instance
            .collection('serviceRequests')
            .where(
              'providerId',
              isEqualTo: user.uid,
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Incoming Requests',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: requestsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load requests: '
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

          final requests =
              snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No incoming requests yet',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final document =
                  requests[index];

              final request =
                  document.data();

              final customerEmail =
                  request['customerEmail']
                          as String? ??
                      'Unknown customer';

              final specialty =
                  request['specialty']
                          as String? ??
                      'Service';

              final serviceDescription =
                  request['serviceDescription']
                          as String? ??
                      '';

              final priceRange =
                  request['priceRange']
                          as String? ??
                      '';

              final status =
                  request['status']
                          as String? ??
                      'Pending';

              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(
                              Icons
                                  .design_services,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Text(
                              specialty,
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  statusColor(
                                status,
                              ).withValues(
                                alpha: 0.15,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color:
                                    statusColor(
                                  status,
                                ),
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (serviceDescription
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          serviceDescription,
                        ),
                      ],

                      if (priceRange
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .payments_outlined,
                              size: 18,
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Text(
                              priceRange,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customerEmail,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              emailCustomer(
                                context,
                                customerEmail:
                                    customerEmail,
                                specialty:
                                    specialty,
                              );
                            },
                            icon: const Icon(
                              Icons.email_outlined,
                            ),
                            label: const Text(
                              'Email Customer',
                            ),
                          ),

                          if (status.toLowerCase() ==
                              'pending')
                            ElevatedButton.icon(
                              onPressed: () {
                                updateStatus(
                                  context,
                                  document.id,
                                  'Accepted',
                                );
                              },
                              icon: const Icon(
                                Icons.check,
                              ),
                              label: const Text(
                                'Accept',
                              ),
                            ),

                          if (status.toLowerCase() ==
                              'pending')
                            OutlinedButton.icon(
                              onPressed: () {
                                updateStatus(
                                  context,
                                  document.id,
                                  'Declined',
                                );
                              },
                              icon: const Icon(
                                Icons.close,
                              ),
                              label: const Text(
                                'Decline',
                              ),
                            ),

                          if (status.toLowerCase() ==
                              'accepted')
                            ElevatedButton.icon(
                              onPressed: () {
                                updateStatus(
                                  context,
                                  document.id,
                                  'Completed',
                                );
                              },
                              icon: const Icon(
                                Icons
                                    .task_alt,
                              ),
                              label: const Text(
                                'Mark Completed',
                              ),
                            ),
                        ],
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