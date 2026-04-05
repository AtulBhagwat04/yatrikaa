import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';

class GuideInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const GuideInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? primaryBlue).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.caption(
                  label,
                  color: appGrey,
                  fontWeight: FontWeight.w600,
                  size: 13,
                ),
                const SizedBox(height: 2),
                AppText.body(value, fontWeight: FontWeight.w800, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
