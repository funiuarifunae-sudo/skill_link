import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in again'),
        ),
      );
    }

    final reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings and Reviews'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load reviews: ${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final reviews = snapshot.data?.docs ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Text('No reviews received yet'),
            );
          }

          double totalRating = 0;

          for (final review in reviews) {
            final data = review.data();
            totalRating +=
                (data['rating'] as num?)?.toDouble() ?? 0.0;
          }

          final averageRating = totalRating / reviews.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reviews.length} review(s)',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index].data();

                    final rating =
                        (review['rating'] as num?)?.toInt() ?? 0;
                    final comment =
                        review['comment'] as String? ?? '';
                    final customerEmail =
                        review['customerEmail'] as String? ??
                            'Customer';

                    return Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (starIndex) => Icon(
              starIndex < rating
                  ? Icons.star
                  : Icons.star_border,
              color: Colors.amber,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          comment.isEmpty
              ? 'No written comment'
              : comment,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'From: $customerEmail',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  ),
);      },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}