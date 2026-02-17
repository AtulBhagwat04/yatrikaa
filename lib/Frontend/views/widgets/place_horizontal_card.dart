import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';

class PlaceHorizontalCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback? onTap;

  const PlaceHorizontalCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: AppSpacing.m, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: place.photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerBox(),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(
                      place.name,
                      color: appWhite,
                      align: TextAlign.left,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
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
                          color: appWhite,
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
