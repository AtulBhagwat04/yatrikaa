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
    Color backgroundColor;
    IconData iconData;
    Color iconColor = Colors.white;

    switch (type) {
      case ToastType.success:
        backgroundColor = successColor;
        iconData = Icons.check_circle_outline;
        break;
      case ToastType.error:
        backgroundColor = errorColor;
        iconData = Icons.error_outline;
        break;
      case ToastType.warning:
        backgroundColor = warningColor;
        iconData = Icons.warning_amber_outlined;
        break;
      case ToastType.info:
        backgroundColor = infoColor;
        iconData = Icons.info_outline;
        break;
      case ToastType.progress:
        backgroundColor = primaryBlue;
        iconData = Icons.sync;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: type == ToastType.progress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              onClose?.call();
            },
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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
