import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';

class ModernSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ModernSectionTitle({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(
            title,
            fontWeight: FontWeight.w700,
            size: 20,
            color: blackOpacity,
          ),
          const Icon(Icons.chevron_right_rounded, color: appGrey, size: 24),
        ],
      ),
    );
  }
}
