import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';

class LocationCard extends StatelessWidget {
  final String location;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const LocationCard({
    super.key,
    required this.location,
    required this.isLoading,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: const Icon(
              Icons.location_on_outlined,
              color: primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(
                    AppStrings.currentLocation,
                    align: TextAlign.left,
                    color: appGrey,
                  ),
                  const SizedBox(height: 2),
                  AppText.body(
                    isLoading ? AppStrings.detectingLocation : location,
                    align: TextAlign.left,
                    fontWeight: FontWeight.w700,
                    color: appBlack,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
