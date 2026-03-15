import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';

class ModernPlaceCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  const ModernPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.width,
    this.height,
    this.radius = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.only(right: AppSpacing.m, bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: place.photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerBox(),
                errorWidget: (context, url, error) => Container(
                  color: appGreyVeryLight,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: appGrey,
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
              // Ratings (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: ratingColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content (Bottom)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.heading(
                      place.name,
                      color: Colors.white,
                      size: 18,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (place.city != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AppText.caption(
                              place.city!,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              size: 13,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
