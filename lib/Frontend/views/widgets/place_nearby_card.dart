import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';

class PlaceNearbyCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback? onTap;

  const PlaceNearbyCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: place.photoUrl,
                height: 90,
                width: 90,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerBox(),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppText.body(
                          place.name,
                          align: TextAlign.left,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppText.caption(
                          place.address ?? AppStrings.nearbyAttraction,
                          align: TextAlign.left,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      AppText.caption(
                        place.rating.toString(),
                        fontWeight: FontWeight.w700,
                      ),
                      if (place.distance != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.directions_car_outlined,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        AppText.caption(
                          "${place.distance!.toStringAsFixed(1)} km",
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
