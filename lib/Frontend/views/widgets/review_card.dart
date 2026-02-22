import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryBlue.withAlpha(25),
                backgroundImage: review.profilePhotoUrl != null
                    ? NetworkImage(review.profilePhotoUrl!)
                    : null,
                child: review.profilePhotoUrl == null
                    ? const Icon(Icons.person, size: 24, color: primaryBlue)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(
                      review.authorName,
                      fontWeight: FontWeight.w800,
                    ),
                    AppText.small(
                      review.relativeTimeDescription,
                      color: Colors.grey[500],
                    ),
                  ],
                ),
              ),
              _buildStarRating(review.rating),
            ],
          ),
          const SizedBox(height: 16),
          AppText.body(
            review.text,
            color: Colors.grey[700],
            maxLines: 3,
            size: 14,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star_rounded, size: 16, color: Colors.amber);
        } else if (index < rating && (rating - index) > 0) {
          return const Icon(
            Icons.star_half_rounded,
            size: 16,
            color: Colors.amber,
          );
        } else {
          return Icon(Icons.star_rounded, size: 16, color: Colors.grey[300]);
        }
      }),
    );
  }
}
