import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderDetailScreen extends StatefulWidget {
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

  @override
  State<ProviderDetailScreen> createState() =>
      _ProviderDetailScreenState();
}

class _ProviderDetailScreenState
    extends State<ProviderDetailScreen> {
  late String _selectedSpecialty;
  late String _selectedDescription;
  late String _selectedPriceRange;

  @override
  void initState() {
    super.initState();

    _selectedSpecialty = widget.specialty;
    _selectedDescription = widget.description;
    _selectedPriceRange = widget.priceRange;
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

    if (services.isEmpty) {
      final category =
          provider['category'] as String? ??
              widget.specialty;

      services.add({
        'category': category,
        'description':
            provider['description'] as String? ??
                widget.description,
        'priceRange':
            provider['priceRange'] as String? ??
                widget.priceRange,
      });
    }

    return services;
  }

  Future<void> openMap(
    BuildContext context,
  ) async {
    final encodedLocation =
        Uri.encodeComponent(widget.location);

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
            'This provider has not added '
            'a WhatsApp number',
          ),
        ),
      );
      return;
    }

    final message =
        'Hi ${widget.name}, I found your '
        '$_selectedSpecialty service on SkillLink. '
        'I would like to discuss a service request.';

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
            'Please log in before requesting '
            'a service',
          ),
        ),
      );
      return;
    }
    if (user.uid == widget.providerId) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'You cannot request your own service',
      ),
    ),
  );
  return;
}

    try {
      final providerProfile =
          await FirebaseFirestore.instance
              .collection('providerProfiles')
              .doc(widget.providerId)
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
        'providerId': widget.providerId,
        'providerName': widget.name,
        'providerWhatsappNumber':
            providerWhatsappNumber,
        'specialty': _selectedSpecialty,
        'serviceDescription':
            _selectedDescription,
        'priceRange': _selectedPriceRange,
        'status': 'Pending',
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_selectedSpecialty request submitted',
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
            .doc(widget.providerId)
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
                  widget.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
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
                        isEqualTo:
                            widget.providerId,
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

                    for (final review
                        in reviews) {
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
                      textAlign:
                          TextAlign.center,
                    );
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Services offered',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Select the service you want '
                  'to request.',
                ),

                const SizedBox(height: 12),

                StreamBuilder<
                    DocumentSnapshot<
                        Map<String, dynamic>>>(
                  stream: providerStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    final provider =
                        snapshot.data?.data() ??
                            <String, dynamic>{};

                    final services =
                        servicesForProvider(
                      provider,
                    );

                    return Column(
                      children: services.map(
                        (service) {
                          final category =
                              service['category'] ??
                                  'Service';

                          final description =
                              service[
                                      'description'] ??
                                  'No description';

                          final price =
                              service[
                                      'priceRange'] ??
                                  'Price unavailable';

                          final isSelected =
                              category ==
                                      _selectedSpecialty &&
                                  description ==
                                      _selectedDescription &&
                                  price ==
                                      _selectedPriceRange;

                          return Card(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : null,
                            child: ListTile(
                              leading: Icon(
                                isSelected
                                    ? Icons
                                        .check_circle
                                    : Icons
                                        .design_services,
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                    : null,
                              ),
                              title: Text(
                                category,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '$description\n$price',
                              ),
                              isThreeLine: true,
                              trailing: isSelected
                                  ? const Text(
                                      'Selected',
                                    )
                                  : const Icon(
                                      Icons
                                          .chevron_right,
                                    ),
                              onTap: () {
                                setState(() {
                                  _selectedSpecialty =
                                      category;

                                  _selectedDescription =
                                      description;

                                  _selectedPriceRange =
                                      price;
                                });
                              },
                            ),
                          );
                        },
                      ).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedSpecialty,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDescription,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedPriceRange,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on,
                    ),
                    title: Text(
                      widget.location,
                    ),
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

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    submitRequest(context);
                  },
                  icon: const Icon(
                    Icons.send_outlined,
                  ),
                  label: Text(
                    'Request $_selectedSpecialty',
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
                        icon: const Icon(
                          Icons.chat,
                        ),
                        label: const Text(
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
                            const Color(
                          0xFF25D366,
                        ),
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
                  'Your request is recorded inside '
                  'SkillLink. WhatsApp is used only '
                  'for discussing the request.',
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