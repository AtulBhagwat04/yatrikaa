import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';

class ModernSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool showPulse;

  const ModernSectionTitle({
    super.key,
    required this.title,
    required this.onTap,
    this.showPulse = false,
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
            fontWeight: FontWeight.w800,
            size: 17,
            color: blackOpacity,
          ),
          showPulse 
            ? const Icon(Icons.chevron_right_rounded, color: primaryBlue, size: 28)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 500.ms, curve: Curves.easeInOut)
                .shimmer(color: Colors.white, duration: 1000.ms)
            : const Icon(Icons.chevron_right_rounded, color: appGrey, size: 24),
        ],
      ),
    );
  }
}
