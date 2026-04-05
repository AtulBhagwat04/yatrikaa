import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CustomAlertType { success, error, info }

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final CustomAlertType type;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'OK',
    this.cancelLabel = 'CANCEL',
    this.icon = Icons.info_outline_rounded,
    this.type = CustomAlertType.info,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on type
    Color primaryColor;
    Color secondaryColor;
    IconData displayIcon = icon;

    switch (type) {
      case CustomAlertType.success:
        primaryColor = successColorDark;
        secondaryColor = successColorLight;
        if (displayIcon == Icons.info_outline_rounded)
          displayIcon = Icons.verified_user_rounded;
        break;
      case CustomAlertType.error:
        primaryColor = errorColor;
        secondaryColor = errorColorLight;
        if (displayIcon == Icons.info_outline_rounded)
          displayIcon = Icons.report_problem_rounded;
        break;
      case CustomAlertType.info:
        primaryColor = primaryBlue;
        secondaryColor = onboardingBlueVeryLight;
        break;
    }

    return Dialog(
      backgroundColor: appWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(displayIcon, size: 50, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: blackOpacity,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: appGrey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (onCancel != null) onCancel!();
                  },
                  child: Container(
                    height: 60,
                    color: secondaryColor,
                    alignment: Alignment.center,
                    child: Text(
                      cancelLabel.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Container(
                    height: 60,
                    color: primaryColor,
                    alignment: Alignment.center,
                    child: Text(
                      confirmLabel.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Static helper to show the dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'OK',
    String cancelLabel = 'CANCEL',
    IconData icon = Icons.info_outline_rounded,
    CustomAlertType type = CustomAlertType.info,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        type: type,
        onCancel: onCancel,
      ),
    );
  }
}
