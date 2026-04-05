import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';

class GenericManagementScreen extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData icon;
  final Color themeColor;

  final String? actionLabel;
  final String? actionRoute;

  const GenericManagementScreen({
    super.key,
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.themeColor,
    this.actionLabel,
    this.actionRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        title: AppText.subHeading(
          title,
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 48),
              ),
              const SizedBox(height: 24),
              AppText.heading(emptyTitle, size: 22, align: TextAlign.center),
              const SizedBox(height: 12),
              AppText.body(
                emptySubtitle,
                align: TextAlign.center,
                color: Colors.grey,
                size: 15,
                height: 1.5,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  if (actionRoute != null) {
                    Navigator.pushNamed(context, actionRoute!);
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(actionLabel ?? 'Return to Profile'),
              ),
              if (actionLabel != null && actionRoute != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: AppText.body(
                    'Go Back',
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
