import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'provider_detail_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String category;

  const ProviderListScreen({
    super.key,
    required this.category,
  });

  @override
  State<ProviderListScreen> createState() =>
      _ProviderListScreenState();
}

class _ProviderListScreenState
    extends State<ProviderListScreen> {
  Position? _customerPosition;
  bool _isFindingLocation = false;

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _useCustomerLocation() async {
    setState(() {
      _isFindingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Turn on Location Services and try again',
        );
        return;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission was denied');
        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is blocked. '
          'Enable it in your device settings.',
        );
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() {
        _customerPosition = position;
      });

      _showMessage(
        'Providers are now sorted by distance',
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to get your location: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFindingLocation = false;
        });
      }
    }
  }

  double? _distanceInKilometres(
    Map<String, dynamic> provider,
  ) {
    final customerPosition = _customerPosition;

    final latitude =
        (provider['latitude'] as num?)?.toDouble();

    final longitude =
        (provider['longitude'] as num?)?.toDouble();

    if (customerPosition == null ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    final distanceInMetres =
        Geolocator.distanceBetween(
      customerPosition.latitude,
      customerPosition.longitude,
      latitude,
      longitude,
    );

    return distanceInMetres / 1000;
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      final metres = (distance * 1000).round();
      return '$metres m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    final providersStream = FirebaseFirestore.instance
        .collection('providerProfiles')
        .where(
          'category',
          isEqualTo: widget.category,
        )
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          IconButton(
            tooltip: 'Use my location',
            onPressed: _isFindingLocation
                ? null
                : _useCustomerLocation,
            icon: _isFindingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              0,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  _customerPosition == null
                      ? Icons.location_searching
                      : Icons.near_me,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _customerPosition == null
                        ? 'Use your location to see the '
                            'nearest providers.'
                        : 'Showing provider distances and '
                            'sorting nearest first.',
                  ),
                ),
                TextButton(
                  onPressed: _isFindingLocation
                      ? null
                      : _useCustomerLocation,
                  child: Text(
                    _customerPosition == null
                        ? 'Use location'
                        : 'Refresh',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: providersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load providers: '
                      '${snapshot.error}',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final providers = [
                  ...?snapshot.data?.docs,
                ];

                if (_customerPosition != null) {
                  providers.sort((first, second) {
                    final firstDistance =
                        _distanceInKilometres(
                      first.data(),
                    );

                    final secondDistance =
                        _distanceInKilometres(
                      second.data(),
                    );

                    if (firstDistance == null &&
                        secondDistance == null) {
                      return 0;
                    }

                    if (firstDistance == null) {
                      return 1;
                    }

                    if (secondDistance == null) {
                      return -1;
                    }

                    return firstDistance.compareTo(
                      secondDistance,
                    );
                  });
                }

                if (providers.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${widget.category} providers '
                      'are available yet',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final document = providers[index];
                    final provider = document.data();

                    final name =
                        provider['businessName']
                                as String? ??
                            'Unnamed provider';

                    final location =
                        provider['location']
                                as String? ??
                            'Location unavailable';

                    final priceRange =
                        provider['priceRange']
                                as String? ??
                            'Price unavailable';

                    final description =
                        provider['description']
                                as String? ??
                            'No description';

                    final rating =
                        (provider['averageRating']
                                    as num?)
                                ?.toDouble() ??
                            0.0;

                    final availabilityStatus =
                        provider['availabilityStatus']
                                as String? ??
                            'offline';

                    final distance =
                        _distanceInKilometres(provider);

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
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
                                const SizedBox(width: 6),
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
                            const SizedBox(height: 4),
                            Text(location),
                            Text(priceRange),
                            if (distance != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.near_me,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatDistance(
                                      distance,
                                    ),
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (
                                _customerPosition != null)
                              const Padding(
                                padding:
                                    EdgeInsets.only(top: 4),
                                child: Text(
                                  'Provider GPS location '
                                  'not available',
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
                                providerId: document.id,
                                name: name,
                                specialty:
                                    widget.category,
                                rating: rating
                                    .toStringAsFixed(1),
                                description: description,
                                location: location,
                                priceRange: priceRange,
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