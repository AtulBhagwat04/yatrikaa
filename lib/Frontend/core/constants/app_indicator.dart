import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppPageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const AppPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: currentIndex == index ? 22 : 6,
          decoration: BoxDecoration(
            color: onboardingBlueDark,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
