import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/review_model.dart';
import 'package:yatrikaa/Frontend/views/widgets/review_card.dart';

class AllReviewsSheet extends StatelessWidget {
  final String title;
  final List<ReviewModel> reviews;
  final String? currentUserId;
  final bool isAdmin;
  final Function(ReviewModel review)? onEdit;
  final Function(ReviewModel review)? onDelete;

  const AllReviewsSheet({
    super.key,
    required this.title,
    required this.reviews,
    this.currentUserId,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header Handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.subHeading(
                      title,
                      fontWeight: FontWeight.w900,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    AppText.caption(
                      '${reviews.length} total experiences',
                      color: appGrey,
                      size: 11,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[50]?.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // Reviews List
          Expanded(
            child: reviews.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return ReviewCard(
                        review: review,
                        currentUserId: currentUserId,
                        isAdmin: isAdmin,
                        margin: EdgeInsets.zero,
                        onEdit: onEdit != null ? () => onEdit!(review) : null,
                        onDelete: onDelete != null
                            ? () => onDelete!(review)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          AppText.subHeading('No Reviews Yet', color: appGrey),
          const SizedBox(height: 8),
          AppText.body(
            'Be the first to share your thoughts!',
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
