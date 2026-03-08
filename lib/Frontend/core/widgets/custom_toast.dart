import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';

enum ToastType { success, error, warning, info, progress }

class CustomToast extends StatelessWidget {
  final String title;
  final String message;
  final ToastType type;
  final VoidCallback? onClose;

  const CustomToast({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;
    late IconData iconData;
    late Color iconColor;

    switch (type) {
      case ToastType.success:
        backgroundColor = successColorLight;
        iconData = Icons.check_circle_rounded;
        iconColor = successColorDark;
        break;
      case ToastType.error:
        backgroundColor = errorColorLight;
        iconData = Icons.error_rounded;
        iconColor = errorColorDark;
        break;
      case ToastType.warning:
        backgroundColor = warningColorLight;
        iconData = Icons.warning_rounded;
        iconColor = warningColorDark;
        break;
      case ToastType.info:
        backgroundColor = onboardingBlueVeryLight;
        iconData = Icons.info_rounded;
        iconColor = primaryBlue;
        break;
      case ToastType.progress:
        backgroundColor = onboardingBlueVeryLight;
        iconData = Icons.sync_rounded;
        iconColor = primaryBlue;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: iconColor.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Accent Bar
              Container(
                width: 6,
                color: iconColor,
              ),
              const SizedBox(width: 16),
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: type == ToastType.progress
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      )
                    : Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          color: appBlack.withOpacity(0.87),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: AppTextStyles.caption.copyWith(
                          color: appBlack.withOpacity(0.54),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Close Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onClose?.call();
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: appGrey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onClose,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: CustomToast(
          title: title,
          message: message,
          type: type,
          onClose: onClose,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // Helper methods for easy access
  static void success(
    BuildContext context,
    String message, {
    String title = 'Success',
  }) {
    show(context, title: title, message: message, type: ToastType.success);
  }

  static void error(
    BuildContext context,
    String message, {
    String title = 'Error',
  }) {
    show(context, title: title, message: message, type: ToastType.error);
  }

  static void info(
    BuildContext context,
    String message, {
    String title = 'Info',
  }) {
    show(context, title: title, message: message, type: ToastType.info);
  }

  static void warning(
    BuildContext context,
    String message, {
    String title = 'Warning',
  }) {
    show(context, title: title, message: message, type: ToastType.warning);
  }

  static void progress(
    BuildContext context,
    String message, {
    String title = 'Processing...',
  }) {
    show(
      context,
      title: title,
      message: message,
      type: ToastType.progress,
      duration: const Duration(seconds: 10),
    );
  }
}
