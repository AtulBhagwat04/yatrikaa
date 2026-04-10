import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  void _shareApp() {
    Share.share(
      'Discover travel destinations with Yatrikaa! Download now from Play Store: https://play.google.com/store/apps/details?id=com.yatrikaa.travel',
      subject: 'Yatrikaa - Your Travel Companion',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Ensure no back button is shown
        title: AppText.heading(
          'About Yatrikaa',
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
            _buildIdentitySection().animate().fadeIn().scale(
              begin: const Offset(0.9, 0.9),
            ),
            const SizedBox(height: 12),
            _buildMissionSection().animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            _buildActionList(context).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            _buildFooter().animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: appWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/logo/LogoRounded.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppText.heading('Yatrikaa', size: 26, fontWeight: FontWeight.w900),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: AppText.caption(
            'v1.0.1 Stable',
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            size: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            AppText.body(
              'India is our beautiful home. We built Yatrikaa with love to help every Indian see the hidden magic of our country. Our goal is simple: to make every trip you take a memory you will cherish forever.',
              align: TextAlign.center,
              height: 1.6,
              size: 14,
              fontWeight: FontWeight.w700,
              color: appBlack.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Container(
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appBlack.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildActionItem(
              title: 'Rate Yatrikaa',
              icon: Icons.star_rounded,
              color: ratingColor,
              onTap: () => CustomToast.info(
                context,
                'App Store rating is coming soon!',
                title: 'Coming Soon',
              ),
            ),
            Divider(
              height: 1,
              color: appGreyVeryLight,
              indent: 56,
              endIndent: 16,
            ),
            _buildActionItem(
              title: 'Invite Friends',
              icon: Icons.share_rounded,
              color: primaryBlue,
              onTap: _shareApp,
            ),
            Divider(
              height: 1,
              color: appGreyVeryLight,
              indent: 56,
              endIndent: 16,
            ),
            _buildActionItem(
              title: 'Official Website',
              icon: Icons.language_rounded,
              color: supportSectionColor,
              onTap: () => CustomToast.info(
                context,
                'Our official website is coming soon!',
                title: 'Coming Soon',
              ),
            ),
            Divider(
              height: 1,
              color: appGreyVeryLight,
              indent: 56,
              endIndent: 16,
            ),
            _buildActionItem(
              title: 'Contact Support',
              icon: Icons.mail_rounded,
              color: guideColor,
              onTap: () => CustomToast.info(
                context,
                'Support chat is coming soon!',
                title: 'Coming Soon',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            AppText.body(
              title,
              fontWeight: FontWeight.w700,
              color: appBlack.withOpacity(0.8),
              size: 14,
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: appGreyLight),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              FontAwesomeIcons.instagram,
              onTap: () => _launchUrl(
                'https://www.instagram.com/yatrikaa.app?igsh=aGYxczg4MXpzODZi',
              ),
            ),
            const SizedBox(width: 24),
            _buildSocialIcon(FontAwesomeIcons.xTwitter, onTap: () {}),
            const SizedBox(width: 24),
            _buildSocialIcon(FontAwesomeIcons.facebook, onTap: () {}),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        AppText.caption(
          '© 2026 Yatrikaa',
          color: appBlack.withOpacity(0.2),
          size: 9,
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appBlack.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: appBlack.withOpacity(0.6), size: 16),
      ),
    );
  }
}
