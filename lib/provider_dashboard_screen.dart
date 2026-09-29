import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'provider_profile_form_screen.dart';
import 'incoming_requests_screen.dart';
import 'provider_reviews_screen.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.business_center,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome, Service Provider',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('My Service Profile'),
              subtitle: const Text(
                'Create or update the services you offer',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const ProviderProfileFormScreen(),
    ),
  );
},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Incoming Requests'),
              subtitle: const Text(
                'View requests submitted by customers',
              ),
              trailing: const Icon(Icons.chevron_right),
               onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IncomingRequestsScreen(),
      ),
                  
                );
              },
            ),
          ),
          Card(
  child: ListTile(
    leading: const Icon(Icons.star),
    title: const Text('Ratings and Reviews'),
    subtitle: const Text(
      'View feedback from customers',
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProviderReviewsScreen(),
        ),
      );
    },
  ),
),
        ],
      ),
    );
  }
}