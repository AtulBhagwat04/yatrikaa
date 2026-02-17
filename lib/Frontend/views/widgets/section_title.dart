import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const SectionTitle({super.key, required this.title, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(title, fontWeight: FontWeight.w700, color: blackOpacity),
        TextButton(
          onPressed: onRefresh,
          child: AppText.caption(
            AppStrings.refresh,
            color: primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
