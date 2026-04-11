import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/review_model.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String? currentUserId;
  final bool isAdmin;
  final double? width;
  final EdgeInsets? margin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    this.currentUserId,
    this.isAdmin = false,
    required this.review,
    this.width,
    this.margin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        currentUserId != null &&
        review.userId != null &&
        currentUserId!.trim() == review.userId!.trim();
        
    final bool canManage = isOwner || isAdmin;

    return Container(
      width: width ?? MediaQuery.of(context).size.width * 0.88,
      margin: margin ?? const EdgeInsets.only(bottom: 12, right: 12, left: 2, top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwner
              ? primaryBlue.withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
          width: isOwner ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Body Padding
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Profile + Info)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOwner
                              ? primaryBlue.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[50],
                        backgroundImage: NetworkImage(
                          review.displayProfilePhoto,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: AppText.subHeading(
                                  review.authorName,
                                  size: 14,
                                  fontWeight: FontWeight.w800,
                                  color: appBlack,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          AppText.small(
                            review.relativeTimeDescription,
                            color: Colors.grey[500]!,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 70), // Reduced safety gap
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ),
                // Review Commentary
                AppText.body(
                  review.text,
                  size: 13.5,
                  fontWeight: FontWeight.w500,
                  color: appBlack.withOpacity(0.85),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  height: 1.5,
                ),
              ],
            ),
          ),

          // Rating Pill (Fixed Corner)
          Positioned(
            top: 14,
            right: canManage ? 30 : 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[50]!.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[200]!.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  AppText.small(
                    review.rating.toStringAsFixed(1),
                    color: Colors.amber[900]!,
                    fontWeight: FontWeight.w900,
                    size: 11,
                  ),
                ],
              ),
            ),
          ),

          // Management Menu
          if (canManage)
            Positioned(top: 2, right: -4, child: _buildMoreMenu(context)),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 22),
      onSelected: (value) {
        if (value == 'edit' && onEdit != null) onEdit!();
        if (value == 'delete' && onDelete != null) onDelete!();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      offset: const Offset(0, 42),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: primaryBlue, size: 22),
              const SizedBox(width: 12),
              AppText.body(
                'Edit Review',
                fontWeight: FontWeight.w600,
                size: 14,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
                size: 22,
              ),
              const SizedBox(width: 12),
              AppText.body(
                'Delete',
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
