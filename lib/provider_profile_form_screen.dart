import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProviderProfileFormScreen extends StatefulWidget {
  const ProviderProfileFormScreen({super.key});

  @override
  State<ProviderProfileFormScreen> createState() =>
      _ProviderProfileFormScreenState();
}

class _ProviderProfileFormScreenState
    extends State<ProviderProfileFormScreen> {
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceRangeController = TextEditingController();

  String _selectedCategory = 'Tutors';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceRangeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

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
      _selectedCategory =
          data?['category'] as String? ?? 'Tutors';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final businessName = _businessNameController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final priceRange = _priceRangeController.text.trim();

    if (user == null) {
      _showMessage('Please log in again');
      return;
    }

    if (businessName.isEmpty ||
        description.isEmpty ||
        location.isEmpty ||
        priceRange.isEmpty) {
      _showMessage('Please complete all fields');
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
        'category': _selectedCategory,
        'description': description,
        'location': location,
        'priceRange': priceRange,
        'averageRating': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage('Provider profile saved');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Unable to save profile: $error');
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business or provider name',
                      prefixIcon: Icon(Icons.storefront),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Service category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tutors',
                        child: Text('Tutors'),
                      ),
                      DropdownMenuItem(
                        value: 'Electricians',
                        child: Text('Electricians'),
                      ),
                      DropdownMenuItem(
                        value: 'Plumbers',
                        child: Text('Plumbers'),
                      ),
                      DropdownMenuItem(
                        value: 'Cleaning Services',
                        child: Text('Cleaning Services'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Service description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location or service area',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceRangeController,
                    decoration: const InputDecoration(
                      labelText: 'Price range',
                      hintText: 'Example: R150 - R300 per hour',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}