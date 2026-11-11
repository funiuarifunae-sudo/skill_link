import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() =>
      _ManageServicesScreenState();
}

class _ManageServicesScreenState
    extends State<ManageServicesScreen> {
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

  final List<Map<String, String>> _services = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _loadServices() async {
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

      final data = profile.data();
      final savedServices = data?['services'];

      if (savedServices is List &&
          savedServices.isNotEmpty) {
        for (final service in savedServices) {
          if (service is! Map) continue;

          final serviceData =
              Map<String, dynamic>.from(service);

          final category =
              serviceData['category'] as String? ?? '';

          final description =
              serviceData['description'] as String? ?? '';

          final priceRange =
              serviceData['priceRange'] as String? ?? '';

          if (category.isNotEmpty) {
            _services.add({
              'category': category,
              'description': description,
              'priceRange': priceRange,
            });
          }
        }
      } else {
        // Convert the provider's existing single service
        // into the first service offering.
        final existingCategory =
            data?['category'] as String? ?? '';

        final existingDescription =
            data?['description'] as String? ?? '';

        final existingPrice =
            data?['priceRange'] as String? ?? '';

        if (existingCategory.isNotEmpty) {
          _services.add({
            'category': existingCategory,
            'description': existingDescription,
            'priceRange': existingPrice,
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to load services: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, String>?> _showServiceDialog({
    Map<String, String>? existingService,
  }) async {
    final existingCategory =
        existingService?['category'] ?? '';

    final existingDescription =
        existingService?['description'] ?? '';

    final existingPrice =
        existingService?['priceRange'] ?? '';

    final isStandardCategory =
        _categories.contains(existingCategory) &&
            existingCategory != 'Other Service';

    String selectedCategory =
        existingCategory.isEmpty
            ? 'Tutors'
            : isStandardCategory
                ? existingCategory
                : 'Other Service';

    final customCategoryController =
        TextEditingController(
      text: selectedCategory == 'Other Service'
          ? existingCategory
          : '',
    );

    final descriptionController =
        TextEditingController(
      text: existingDescription,
    );

    final priceController =
        TextEditingController(
      text: existingPrice,
    );

    String? errorMessage;

    final result =
        await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                existingService == null
                    ? 'Add Service'
                    : 'Edit Service',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedCategory,
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
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedCategory =
                                value;
                            errorMessage = null;
                          });
                        },
                      ),

                      if (selectedCategory ==
                          'Other Service') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller:
                              customCategoryController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Custom category',
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
                            descriptionController,
                        maxLines: 3,
                        textCapitalization:
                            TextCapitalization
                                .sentences,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Service description',
                          hintText:
                              'Describe this specific service',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(
                            Icons.description_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: priceController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Price or price range',
                          hintText:
                              'Example: R250 per hour',
                          prefixIcon: Icon(
                            Icons.payments_outlined,
                          ),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final category =
                        selectedCategory ==
                                'Other Service'
                            ? customCategoryController
                                .text
                                .trim()
                            : selectedCategory;

                    final description =
                        descriptionController.text
                            .trim();

                    final price =
                        priceController.text.trim();

                    if (category.length < 3 ||
                        description.isEmpty ||
                        price.isEmpty) {
                      setDialogState(() {
                        errorMessage =
                            'Complete the category, '
                            'description and price.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'category': category,
                        'description':
                            description,
                        'priceRange': price,
                      },
                    );
                  },
                  child: Text(
                    existingService == null
                        ? 'Add'
                        : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    customCategoryController.dispose();
    descriptionController.dispose();
    priceController.dispose();

    return result;
  }

  Future<void> _addService() async {
    final service =
        await _showServiceDialog();

    if (service == null || !mounted) {
      return;
    }

    setState(() {
      _services.add(service);
    });
  }

  Future<void> _editService(int index) async {
    final service =
        await _showServiceDialog(
      existingService: _services[index],
    );

    if (service == null || !mounted) {
      return;
    }

    setState(() {
      _services[index] = service;
    });
  }

  Future<void> _removeService(int index) async {
    final shouldRemove =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Service'),
          content: Text(
            'Remove ${_services[index]['category']} '
            'from your services?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true && mounted) {
      setState(() {
        _services.removeAt(index);
      });
    }
  }

  Future<void> _saveServices() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in again');
      return;
    }

    if (_services.isEmpty) {
      _showMessage(
        'Add at least one service',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final firstService = _services.first;

      final serviceCategories = _services
          .map(
            (service) =>
                service['category']!,
          )
          .toSet()
          .toList();

      await FirebaseFirestore.instance
          .collection('providerProfiles')
          .doc(user.uid)
          .set({
        'services': _services,
        'serviceCategories':
            serviceCategories,

        // Keep these fields for compatibility
        // with existing parts of the app.
        'category':
            firstService['category'],
        'description':
            firstService['description'],
        'priceRange':
            firstService['priceRange'],

        'updatedAt':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage(
        'Services saved successfully',
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to save services: $error',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Services you offer',
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
                  'Add a separate description and '
                  'price for every service you provide.',
                ),

                const SizedBox(height: 20),

                if (_services.isEmpty)
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.design_services,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No services added yet',
                          ),
                        ],
                      ),
                    ),
                  ),

                for (var index = 0;
                    index < _services.length;
                    index++)
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            '${index + 1}',
                          ),
                        ),
                        title: Text(
                          _services[index]
                                  ['category'] ??
                              'Service',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 6,
                          ),
                          child: Text(
                            '${_services[index]['description']}\n'
                            '${_services[index]['priceRange']}',
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip:
                                  'Edit service',
                              onPressed: () {
                                _editService(
                                  index,
                                );
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                              ),
                            ),
                            IconButton(
                              tooltip:
                                  'Remove service',
                              onPressed: () {
                                _removeService(
                                  index,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed:
                      _isSaving ? null : _addService,
                  icon: const Icon(Icons.add),
                  label:
                      const Text('Add Another Service'),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : _saveServices,
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
                        ? 'Saving services...'
                        : 'Save All Services',
                  ),
                ),
              ],
            ),
    );
  }
}