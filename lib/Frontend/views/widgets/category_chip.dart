import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : primaryWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryWhite : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            AppText.caption(
              label,
              color: isSelected ? primaryWhite : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
