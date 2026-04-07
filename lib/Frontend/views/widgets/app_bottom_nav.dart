import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Standard bottom padding
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).padding.bottom +
            8, // Tighter bottom safe area
        left: 11,
        right: 11,
      ),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 4, // Reduce from 8 to 4 for tighter edges
            ), // Tighter vertical
            decoration: BoxDecoration(
              color: appWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryBlue.withOpacity(0.30),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, AppStrings.navHome),
                _navItem(1, Icons.near_me_rounded, AppStrings.navNearby),
                _navItem(2, Icons.groups_rounded, AppStrings.navCommunity),
                _navItem(3, Icons.luggage_rounded, AppStrings.navPackages),
                _navItem(4, Icons.person_rounded, AppStrings.navProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isActive = selectedIndex == index;
    // We use a Flexible here to ensure the Row doesn't overflow if multiple items
    // are in a transitional state (one expanding, one shrinking).
    return Flexible(
      flex: isActive ? 0 : 0,
      child: GestureDetector(
        onTap: () => onItemSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isActive
                ? 12
                : 8, // Tighter horizontal for overflow safety
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? primaryBlue.withOpacity(0.25)
                    : Colors.transparent,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : appGreyDark.withOpacity(0.7),
                  size: 20, // Slightly smaller for production safety
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6), // Smaller gap
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip, // Clip if literally no space
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11, // Tighter font for production safety
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
