import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';

class CompactTag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;

  const CompactTag({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? primaryBlue;
    final bg = backgroundColor ?? effectiveColor.withAlpha(20);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: backgroundColor != null
              ? Colors.transparent
              : effectiveColor.withAlpha(38),
        ),
      ),
      child: AppText.small(
        label.toUpperCase(),
        color:
            color ?? (backgroundColor != null ? Colors.white : effectiveColor),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
