import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

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
        color: primaryWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 2),
                  AppText.body(
                    isLoading ? AppStrings.detectingLocation : location,
                    align: TextAlign.left,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onRefresh();
                    },
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                  ),
          ),
        ],
      ),
    );
  }
}
