import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'review_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  Future<void> openWhatsapp(
    BuildContext context, {
    required String number,
    required String providerName,
    required String specialty,
  }) async {
    final cleanNumber = number.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp contact is unavailable '
            'for this request',
          ),
        ),
      );
      return;
    }

    final message =
        'Hi $providerName, I am contacting you '
        'about my $specialty request on SkillLink.';

    final whatsappUrl = Uri.parse(
      'https://wa.me/$cleanNumber'
      '?text=${Uri.encodeComponent(message)}',
    );

    final opened = await launchUrl(
      whatsappUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open WhatsApp',
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
              'customerId',
              isEqualTo: user.uid,
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
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
                'You have not submitted '
                'any requests',
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

              final providerId =
                  request['providerId']
                          as String? ??
                      '';

              final providerName =
                  request['providerName']
                          as String? ??
                      'Unknown provider';

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

              final whatsappNumber =
                  request[
                              'providerWhatsappNumber']
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
                              Icons.business,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Text(
                              providerName,
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

                      const SizedBox(height: 16),

                      Text(
                        specialty,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),

                      if (serviceDescription
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
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
                              Icons.payments_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
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

                      if (whatsappNumber
                          .isNotEmpty) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            openWhatsapp(
                              context,
                              number:
                                  whatsappNumber,
                              providerName:
                                  providerName,
                              specialty:
                                  specialty,
                            );
                          },
                          icon: const Icon(
                            Icons.chat,
                          ),
                          label: const Text(
                            'WhatsApp Provider',
                          ),
                        ),
                      ],

                      if (status.toLowerCase() ==
                          'completed') ...[
                        const SizedBox(height: 16),

                        StreamBuilder<
                            DocumentSnapshot<
                                Map<String,
                                    dynamic>>>(
                          stream:
                              FirebaseFirestore
                                  .instance
                                  .collection(
                                    'reviews',
                                  )
                                  .doc(
                                    document.id,
                                  )
                                  .snapshots(),
                          builder: (
                            context,
                            reviewSnapshot,
                          ) {
                            if (reviewSnapshot
                                    .connectionState ==
                                ConnectionState
                                    .waiting) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            if (reviewSnapshot
                                    .data
                                    ?.exists ==
                                true) {
                              return const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .check_circle,
                                    color:
                                        Colors.green,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Review submitted',
                                  ),
                                ],
                              );
                            }

                            return ElevatedButton
                                .icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReviewScreen(
                                      requestId:
                                          document
                                              .id,
                                      providerId:
                                          providerId,
                                      providerName:
                                          providerName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.star,
                              ),
                              label: const Text(
                                'Rate Service',
                              ),
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