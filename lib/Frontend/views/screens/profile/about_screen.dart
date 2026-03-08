import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(automaticallyImplyLeading: false, 
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        title: AppText.subHeading(
          'About Bhatkanti',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: primaryBlue,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            AppText.heading('Bhatkanti', size: 28),
            AppText.caption('Version 1.0.0 (Stable)', color: Colors.grey),
            const SizedBox(height: AppSpacing.xl),
            AppText.body(
              'Bhatkanti is your ultimate travel companion, designed to help you discover hidden gems, plan unforgettable trips, and connect with expert local guides. Our mission is to make travel authentic, accessible, and deeply personal for every explorer.',
              align: TextAlign.center,
              size: 15,
              height: 1.6,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildInfoTile(
              Icons.language_rounded,
              'Website',
              'www.bhatkanti.com',
            ),
            _buildInfoTile(
              Icons.mail_outline_rounded,
              'Contact Us',
              'support@bhatkanti.com',
            ),
            _buildInfoTile(Icons.share_outlined, 'Follow Us', '@bhatkanti_app'),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.l),
            AppText.small(
              '© 2026 Bhatkanti. All rights reserved.',
              color: Colors.grey,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryBlue),
          const SizedBox(width: 16),
          AppText.body(title, fontWeight: FontWeight.w600),
          const Spacer(),
          AppText.body(value, color: primaryBlue, size: 14),
        ],
      ),
    );
  }
}
