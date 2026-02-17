import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isLoading
              ? const SizedBox(
            key: ValueKey("loader"),
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : Text(
            text,
            key: const ValueKey("text"),
            style: AppTextStyles.button,
          ),
        ),
      ),
    );
  }
}
