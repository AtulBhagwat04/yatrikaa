import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel = AppStrings.refresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(title, fontWeight: FontWeight.w700, color: blackOpacity),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: AppText.caption(
            actionLabel,
            color: primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
