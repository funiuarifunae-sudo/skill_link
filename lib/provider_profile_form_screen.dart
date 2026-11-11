import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class ProviderProfileFormScreen extends StatefulWidget {
  const ProviderProfileFormScreen({super.key});

  @override
  State<ProviderProfileFormScreen> createState() =>
      _ProviderProfileFormScreenState();
}

class _ProviderProfileFormScreenState
    extends State<ProviderProfileFormScreen> {
  static const List<String> _categories = [
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
    'Other Service',
  ];

  final _businessNameController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceRangeController = TextEditingController();

  String _selectedCategory = 'Tutors';

  double? _latitude;
  double? _longitude;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFindingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _customCategoryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceRangeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection('providerProfiles')
          .doc(user.uid)
          .get();

      if (profile.exists) {
        final data = profile.data();

        _businessNameController.text =
            data?['businessName'] as String? ?? '';

        _descriptionController.text =
            data?['description'] as String? ?? '';

        _locationController.text =
            data?['location'] as String? ?? '';

        _priceRangeController.text =
            data?['priceRange'] as String? ?? '';

        _latitude =
            (data?['latitude'] as num?)?.toDouble();

        _longitude =
            (data?['longitude'] as num?)?.toDouble();

        final savedCategory =
            data?['category'] as String? ?? 'Tutors';

        if (_categories.contains(savedCategory) &&
            savedCategory != 'Other Service') {
          _selectedCategory = savedCategory;
        } else {
          _selectedCategory = 'Other Service';

          if (savedCategory != 'Other Service') {
            _customCategoryController.text = savedCategory;
          }
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to load profile: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
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
String detectedLocation;

if (kIsWeb) {
  // Reverse geocoding is unavailable through this package on Chrome.
  // Coordinates still work with Google Maps.
  detectedLocation =
      '${position.latitude.toStringAsFixed(6)}, '
      '${position.longitude.toStringAsFixed(6)}';
} else {
  try {
    final geocoding = Geocoding();

final placemarks = await geocoding.placemarkFromCoordinates(
  position.latitude,
  position.longitude,
);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      final addressParts = <String>[
        if ((place.street ?? '').isNotEmpty)
          place.street!,
        if ((place.subLocality ?? '').isNotEmpty)
          place.subLocality!,
        if ((place.locality ?? '').isNotEmpty)
          place.locality!,
        if ((place.administrativeArea ?? '').isNotEmpty)
          place.administrativeArea!,
        if ((place.postalCode ?? '').isNotEmpty)
          place.postalCode!,
      ];

      detectedLocation = addressParts.toSet().join(', ');
    } else {
      detectedLocation =
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}';
    }
  } catch (_) {
    detectedLocation =
        '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}';
  }
}

if (!mounted) return;

setState(() {
  _latitude = position.latitude;
  _longitude = position.longitude;
  _locationController.text = detectedLocation;
});

_showMessage(
  'Location detected. Check the address, then save your profile.',
);
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to get GPS location: $error',
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

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    final businessName =
        _businessNameController.text.trim();

    final description =
        _descriptionController.text.trim();

    final location =
        _locationController.text.trim();

    final priceRange =
        _priceRangeController.text.trim();

    final category =
        _selectedCategory == 'Other Service'
            ? _customCategoryController.text.trim()
            : _selectedCategory;

    if (user == null) {
      _showMessage('Please log in again');
      return;
    }

    if (businessName.isEmpty ||
        category.isEmpty ||
        description.isEmpty ||
        location.isEmpty ||
        priceRange.isEmpty) {
      _showMessage('Please complete all fields');
      return;
    }

    if (_selectedCategory == 'Other Service' &&
        category.length < 3) {
      _showMessage(
        'Enter a clear name for your service category',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('providerProfiles')
          .doc(user.uid)
          .set({
        'providerId': user.uid,
        'providerEmail': user.email,
        'businessName': businessName,
        'category': category,
        'description': description,
        'location': location,
        'priceRange': priceRange,

        if (_latitude != null &&
            _longitude != null) ...{
          'latitude': _latitude,
          'longitude': _longitude,
          'locationUpdatedAt':
              FieldValue.serverTimestamp(),
        },

        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage(
        'Provider profile saved successfully',
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to save profile: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Service Profile'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 650,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.storefront,
                            size: 56,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your service profile',
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
                          const Text(
                            'Customers use these details '
                            'to discover and contact your service.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          TextField(
                            controller:
                                _businessNameController,
                            textCapitalization:
                                TextCapitalization.words,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Business or provider name',
                              prefixIcon:
                                  Icon(Icons.storefront),
                            ),
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue:
                                _selectedCategory,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Service category',
                              prefixIcon: Icon(
                                Icons.category_outlined,
                              ),
                            ),
                            items: _categories
                                .map(
                                  (category) =>
                                      DropdownMenuItem<
                                          String>(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedCategory =
                                          value;
                                    });
                                  },
                          ),

                          if (_selectedCategory ==
                              'Other Service') ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller:
                                  _customCategoryController,
                              textCapitalization:
                                  TextCapitalization.words,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Your service category',
                                hintText:
                                    'Example: Tailoring',
                                prefixIcon: Icon(
                                  Icons.edit_outlined,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          TextField(
                            controller:
                                _descriptionController,
                            maxLines: 4,
                            textCapitalization:
                                TextCapitalization
                                    .sentences,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Service description',
                              hintText:
                                  'Explain the services you offer',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(
                                Icons.description_outlined,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller:
                                _locationController,
                            textCapitalization:
                                TextCapitalization.words,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Full service address or area',
                              hintText:
                                  'Use a location Google Maps can find',
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          OutlinedButton.icon(
                            onPressed:
                                _isFindingLocation ||
                                        _isSaving
                                    ? null
                                    : _useCurrentLocation,
                            icon: _isFindingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                  ),
                            label: Text(
                              _isFindingLocation
                                  ? 'Finding location...'
                                  : _latitude == null
                                      ? 'Use My Current GPS Location'
                                      : 'Update My GPS Location',
                            ),
                          ),

                          if (_latitude != null &&
                              _longitude != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color:
                                      colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'GPS location captured '
                                    'and ready to save',
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          TextField(
                            controller:
                                _priceRangeController,
                            decoration:
                                const InputDecoration(
                              labelText: 'Price range',
                              hintText:
                                  'Example: R150 - R300 per hour',
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                              ),
                            ),
                          ),

                          const SizedBox(height: 26),

                          ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_outlined,
                                  ),
                            label: Text(
                              _isSaving
                                  ? 'Saving profile...'
                                  : 'Save Profile',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}