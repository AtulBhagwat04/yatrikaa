import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';

enum ToastType { success, error, warning, info, progress }

class CustomToast extends StatelessWidget {
  final String title;
  final String message;
  final ToastType type;
  final VoidCallback? onClose;
  final double? progressValue; // 0.0 to 1.0

  const CustomToast({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onClose,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    late Color accentColor;
    late IconData iconData;
    late Color lightAccent;

    switch (type) {
      case ToastType.success:
        accentColor = successColorDark;
        lightAccent = successColorLight;
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        accentColor = errorColorDark;
        lightAccent = errorColorLight;
        iconData = Icons.error_rounded;
        break;
      case ToastType.warning:
        accentColor = warningColorDark;
        lightAccent = warningColorLight;
        iconData = Icons.warning_rounded;
        break;
      case ToastType.info:
        accentColor = primaryBlue;
        lightAccent = onboardingBlueVeryLight;
        iconData = Icons.info_rounded;
        break;
      case ToastType.progress:
        accentColor = primaryBlue;
        lightAccent = onboardingBlueVeryLight;
        iconData = Icons.sync_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: type == ToastType.progress
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          )
                        : Icon(iconData, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  // Text Content
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close Button
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.black26,
                      size: 20,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            // Progress Bar (Life indicator)
            if (progressValue != null)
              SizedBox(
                height: 3,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: lightAccent.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor.withOpacity(0.7)),
                ),
              ),
          ],
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
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onRemove: () {
          overlayEntry.remove();
          onClose?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
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

class _ToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onRemove;

  const _ToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onRemove,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _progressController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_progressController);

    // Initial enter
    _controller.forward();

    // Start progress bar and handle removal
    _progressController.forward().then((_) {
      if (mounted) {
        _controller.reverse().then((_) => widget.onRemove());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomToast(
                  title: widget.title,
                  message: widget.message,
                  type: widget.type,
                  progressValue: _progressAnimation.value,
                  onClose: () {
                    _controller.reverse().then((_) => widget.onRemove());
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
