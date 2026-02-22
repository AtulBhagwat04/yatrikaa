import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';

class GenericManagementScreen extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData icon;
  final Color themeColor;

  const GenericManagementScreen({
    super.key,
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: appBlack,
            size: 20,
          ),
        ),
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
                onPressed: () => Navigator.pop(context),
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
                child: const Text('Return to Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
