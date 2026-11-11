import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderDetailScreen extends StatelessWidget {
  final String providerId;
  final String name;
  final String specialty;
  final String rating;
  final String description;
  final String location;
  final String priceRange;

  const ProviderDetailScreen({
    super.key,
    required this.providerId,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.description,
    required this.location,
    required this.priceRange,
  });

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

  Future<void> openMap(BuildContext context) async {
    final encodedLocation =
        Uri.encodeComponent(location);

    final mapUrl = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=$encodedLocation',
    );

    final opened = await launchUrl(
      mapUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Google Maps',
          ),
        ),
      );
    }
  }

  Future<void> openWhatsapp(
    BuildContext context,
    String number,
  ) async {
    final cleanNumber = number.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This provider has not added a WhatsApp number',
          ),
        ),
      );
      return;
    }

    final message =
        'Hi $name, I found your $specialty service '
        'on SkillLink. I would like to discuss a '
        'service request.';

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

  Future<void> submitRequest(
    BuildContext context,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in before requesting a service',
          ),
        ),
      );
      return;
    }

    try {
      final providerProfile =
          await FirebaseFirestore.instance
              .collection('providerProfiles')
              .doc(providerId)
              .get();

      final providerData =
          providerProfile.data();

      final providerWhatsappNumber =
          providerData?['whatsappNumber']
                  as String? ??
              '';

      await FirebaseFirestore.instance
          .collection('serviceRequests')
          .add({
        'customerId': user.uid,
        'customerEmail': user.email,
        'providerId': providerId,
        'providerName': name,
        'providerWhatsappNumber':
            providerWhatsappNumber,
        'specialty': specialty,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Service request submitted',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request failed: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerStream =
        FirebaseFirestore.instance
            .collection('providerProfiles')
            .doc(providerId)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 750,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 48,
                  child: Icon(
                    Icons.person,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  specialty,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                StreamBuilder<
                    DocumentSnapshot<
                        Map<String, dynamic>>>(
                  stream: providerStream,
                  builder: (context, snapshot) {
                    final data =
                        snapshot.data?.data();

                    final status =
                        data?['availabilityStatus']
                                as String? ??
                            'offline';

                    return Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 14,
                          color:
                              availabilityColor(
                            status,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          availabilityLabel(status),
                          style: TextStyle(
                            color:
                                availabilityColor(
                              status,
                            ),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where(
                        'providerId',
                        isEqualTo: providerId,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Text(
                        'Loading rating...',
                        textAlign:
                            TextAlign.center,
                      );
                    }

                    final reviews =
                        snapshot.data?.docs ?? [];

                    if (reviews.isEmpty) {
                      return const Text(
                        'No ratings yet',
                        textAlign:
                            TextAlign.center,
                      );
                    }

                    double total = 0;

                    for (final review in reviews) {
                      total +=
                          (review.data()['rating']
                                      as num?)
                                  ?.toDouble() ??
                              0.0;
                    }

                    final average =
                        total / reviews.length;

                    return Text(
                      'Rating: '
                      '${average.toStringAsFixed(1)} '
                      '(${reviews.length} review(s))',
                      textAlign: TextAlign.center,
                    );
                  },
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Text(description),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on,
                    ),
                    title: Text(location),
                    subtitle:
                        const Text('Service area'),
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    openMap(context);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text(
                    'View on Google Maps',
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.payments,
                    ),
                    title: Text(priceRange),
                    subtitle:
                        const Text('Price range'),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    submitRequest(context);
                  },
                  icon: const Icon(
                    Icons.send_outlined,
                  ),
                  label: const Text(
                    'Request Service',
                  ),
                ),

                const SizedBox(height: 12),

                StreamBuilder<
                    DocumentSnapshot<
                        Map<String, dynamic>>>(
                  stream: providerStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const OutlinedButton(
                        onPressed: null,
                        child: Text(
                          'Loading contact details...',
                        ),
                      );
                    }

                    final data =
                        snapshot.data?.data();

                    final whatsappNumber =
                        data?['whatsappNumber']
                                as String? ??
                            '';

                    if (whatsappNumber.isEmpty) {
                      return OutlinedButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.chat),
                        label: Text(
                          'WhatsApp number unavailable',
                        ),
                      );
                    }

                    return ElevatedButton.icon(
                      onPressed: () {
                        openWhatsapp(
                          context,
                          whatsappNumber,
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF25D366),
                        foregroundColor:
                            Colors.white,
                      ),
                      icon: const Icon(
                        Icons.chat,
                      ),
                      label: const Text(
                        'WhatsApp Provider',
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                const Text(
                  'Your service request is recorded '
                  'inside SkillLink. WhatsApp is used '
                  'only for discussing the request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}