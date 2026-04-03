import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        title: AppText.subHeading(
          'Privacy Policy',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(
              'Last Updated: February 2026',
              color: Colors.grey,
              size: 12,
            ),
            const SizedBox(height: AppSpacing.l),
            _buildSection(
              '1. Information We Collect',
              'We collect information that you provides directly to us, such as when you create an account, update your profile, or use our travel planning features. This includes your name, email address, and trip preferences.',
            ),
            _buildSection(
              '2. How We Use Your Data',
              'Your data is used to provide and improve Bhatkanti services, customize your travel recommendations, and facilitate interactions with guides and other travelers.',
            ),
            _buildSection(
              '3. Data Security',
              'We implement industry-standard security measures to protect your personal information from unauthorized access, disclosure, or destruction.',
            ),
            _buildSection(
              '4. Your Rights',
              'You have the right to access, update, or delete your personal information at any time through your account settings or by contacting our support team.',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(title, fontWeight: FontWeight.bold, size: 16),
        const SizedBox(height: 8),
        AppText.body(
          content,
          size: 14,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
        const SizedBox(height: AppSpacing.l),
      ],
    );
  }
}
