import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/review_model.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String? currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOwner = currentUserId != null &&
        review.userId != null &&
        currentUserId!.trim() == review.userId!.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      // ... same decoration ...
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                backgroundImage: NetworkImage(review.displayProfilePhoto),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStarRating(review.rating),
                      if (isOwner) ...[
                        const SizedBox(width: 4),
                        _buildMoreMenu(context),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppText.body(
            review.text,
            color: Colors.grey[700],
            maxLines: 5, // Increased maxLines
            size: 14,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 120),
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600], size: 22), // More prominent icon
      onSelected: (value) {
        if (value == 'edit' && onEdit != null) onEdit!();
        if (value == 'delete' && onDelete != null) onDelete!();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: primaryBlue),
              const SizedBox(width: 10),
              AppText.body('Edit', size: 14),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              AppText.body('Delete', size: 14, color: Colors.red),
            ],
          ),
        ),
      ],
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
