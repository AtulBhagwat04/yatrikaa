import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';

class PlaceNearbyCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback? onTap;

  const PlaceNearbyCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: CachedNetworkImage(
                        imageUrl: place.photoUrl,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerBox(),
                        errorWidget: (context, url, error) => Container(
                          height: 100,
                          width: 100,
                          color: onboardingBlueVeryLight,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: appGrey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (place.distance != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: overlayColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText.small(
                            "${place.distance!.toStringAsFixed(1)}km",
                            color: appWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // prevent column from expanding infinitely vertically
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppText.small(
                          place.category?.toUpperCase() ?? "TRAVEL",
                          color: primaryBlue,
                          fontWeight: FontWeight.w800,
                          size: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: AppText.body(
                          place.name,
                          fontWeight: FontWeight.w800,
                          maxLines: 2,
                          size: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: appGrey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AppText.caption(
                              [place.city, place.state]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(", "),
                              color: appGrey,
                              size: 11,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (place.distance != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.compare_arrows,
                              color: primaryBlue,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            AppText.caption(
                              "${place.distance!.toStringAsFixed(1)} KM",
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                              size: 11,
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: ratingColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            AppText.caption(
                              place.rating.toString(),
                              fontWeight: FontWeight.w800,
                            ),
                            AppText.caption(
                              " (${place.userRatingsTotal})",
                              color: appGreyLight,
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
      ),
    );
  }
}
