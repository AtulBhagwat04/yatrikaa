import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final Color? backgroundColor;
  final Color? textColor;

  const RatingBadge({
    super.key,
    required this.rating,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Colors.amber.withAlpha(50), // Replaced withOpacity(0.15)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          AppText.body(
            rating.toString(),
            fontWeight: FontWeight.w800,
            color: textColor ?? Colors.amber[800],
          ),
        ],
      ),
    );
  }
}
