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
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isActive = selectedIndex == index;
    // We use a Flexible here to ensure the Row doesn't overflow if multiple items
    return Flexible(
      flex: isActive ? 1 : 0,
      child: GestureDetector(
        onTap: () => onItemSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 14 : 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isActive ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? primaryBlue.withValues(alpha: 0.25)
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
                  color: isActive ? Colors.white : appGreyDark,
                  size: 24,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
