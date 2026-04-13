import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: AppText.heading(
          'Privacy Policy',
          fontWeight: FontWeight.w900,
          size: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildIntroCard().animate().fadeIn().moveY(begin: 10, end: 0),
            const SizedBox(height: 12),
            _buildSection(
              '1. Information We Collect',
              'We collect information that you provides directly to us, such as when you create an account, update your profile, or use our travel planning features. This includes your name, email address, and trip preferences.',
            ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
            _buildSection(
              '2. How We Use Your Data',
              'Your data is used to provide and improve Yatrikaa services, customize your travel recommendations, and facilitate interactions with guides and other travelers.',
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 10, end: 0),
            _buildSection(
              '3. Data Security',
              'We implement industry-standard security measures to protect your personal information from unauthorized access, disclosure, or destruction.',
            ).animate().fadeIn(delay: 600.ms).moveY(begin: 10, end: 0),
            _buildSection(
              '4. Your Rights',
              'You have the right to access, update, or delete your personal information at any time through your account settings or by contacting our support team.',
            ).animate().fadeIn(delay: 800.ms).moveY(begin: 10, end: 0),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.caption(
              'Last Updated: February 2026',
              fontWeight: FontWeight.w800,
              color: primaryBlue,
              size: 11,
            ),
            const SizedBox(height: 12),
            AppText.body(
              'Your privacy is important to us. This policy explains how we handle your data to give you the best travel experience in India.',
              fontWeight: FontWeight.w700,
              size: 14,
              color: appBlack.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appBlack.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(title, fontWeight: FontWeight.w900, size: 16),
            const SizedBox(height: 12),
            AppText.body(
              content,
              size: 13,
              height: 1.6,
              color: appBlack.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
