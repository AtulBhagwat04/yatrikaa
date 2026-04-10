import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

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
      'Discover travel destinations with Yatrikaa! Download now: https://www.yatrikaa.com/download',
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
        scrolledUnderElevation: 2,
        surfaceTintColor: appWhite,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: appBlack,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText.heading(
          'About Yatrikaa',
          fontWeight: FontWeight.w900,
          size: 20,
        ),
      ),
      body: Stack(
        children: [
          // --- Background Mandala Pattern ---
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/background_pattern.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.m),

                  // --- 1. App Identity Section ---
                  _buildIdentitySection()
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scaleXY(begin: 0.98),

                  const SizedBox(height: AppSpacing.ml),

                  // --- 2. Direct Content (Standard Padding) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    child: _buildProperAboutContent(),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppSpacing.ml),

                  // --- 3. Engagement Actions ---
                  _SectionGroup(
                    heading: 'Engagement',
                    items: [
                      _SectionItem(
                        icon: Icons.star_rounded,
                        label: 'Rate on Play Store',
                        color: ratingColor,
                        onTap: () {},
                      ),
                      _SectionItem(
                        icon: Icons.share_rounded,
                        label: 'Invite Friends',
                        color: primaryBlue,
                        onTap: _shareApp,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.m),

                  // --- 4. Support & Legal Section ---
                  _SectionGroup(
                    heading: 'Connect & Legal',
                    items: [
                      _SectionItem(
                        icon: Icons.language_rounded,
                        label: 'Official Website',
                        color: supportSectionColor,
                        onTap: () => _launchUrl('https://www.yatrikaa.com'),
                      ),
                      _SectionItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        color: supportSectionColor,
                        onTap: () {},
                      ),
                      _SectionItem(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        color: supportSectionColor,
                        onTap: () {},
                      ),
                      _SectionItem(
                        icon: Icons.code_rounded,
                        label: 'Open Source Licenses',
                        color: supportSectionColor,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // --- 5. Footer ---
                  _buildFooter(),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryBlue.withOpacity(0.1), width: 3),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child:
              Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset('assets/logo/LogoRounded.png'),
                      ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .shimmer(duration: 3.seconds, color: Colors.white24)
                  .scaleXY(
                    begin: 1.0,
                    end: 1.03,
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        const SizedBox(height: 12),
        AppText.heading(
          'Yatrikaa',
          size: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: primaryBlue.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, color: primaryBlue, size: 12),
              const SizedBox(width: 6),
              AppText.caption(
                'Build v1.0.1 Stable',
                fontWeight: FontWeight.w900,
                color: primaryBlue,
                size: 11,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProperAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(
          'About Yatrikaa',
          size: 19,
          fontWeight: FontWeight.w900,
        ),
        const SizedBox(height: AppSpacing.s),

        AppText.body(
          'Yatrikaa is a one-stop travel platform built to make exploring India easier for everyone. We believe that travel is the best way to discover the true beauty of Bharat and connect with our roots.',
          align: TextAlign.start,
          height: 1.6,
          color: appBlack.withOpacity(0.8),
          size: 14,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: AppSpacing.s),
        AppText.body(
          'Our platform provides simple tools to help you plan trips, discover historic hidden gems, and experience local culture. Whether you are looking for peaceful beaches, ancient forts, or busy city life, we are your trusted partner for every adventure.',
          align: TextAlign.start,
          height: 1.6,
          color: appBlack.withOpacity(0.8),
          size: 14,
          fontWeight: FontWeight.w500,
        ),

        const SizedBox(height: AppSpacing.m),
        Divider(color: appBlack.withOpacity(0.1), height: 1),
        const SizedBox(height: AppSpacing.m),

        AppText.caption(
          'Welcome to the Yatrikaa family!',
          fontWeight: FontWeight.w900,
          color: primaryBlue,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(FontAwesomeIcons.instagram),
            const SizedBox(width: 28),
            _buildSocialIcon(FontAwesomeIcons.xTwitter),
            const SizedBox(width: 28),
            _buildSocialIcon(FontAwesomeIcons.facebook),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        AppText.caption(
          'Crafted with 💖 for Bharat',
          fontWeight: FontWeight.w900,
          color: appGrey,
          size: 10,
        ),
        const SizedBox(height: 4),
        AppText.small(
          '© 2026 Yatrikaa Travel Tech',
          color: appGrey.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Icon(icon, color: appGrey, size: 20).animate().scale(delay: 800.ms);
  }
}

// ─── Refined Section Components ─────────────────────────────────

class _SectionGroup extends StatelessWidget {
  final String heading;
  final List<_SectionItem> items;

  const _SectionGroup({required this.heading, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: AppText.caption(
              heading.toUpperCase(),
              color: appGrey,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              size: 10,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: appWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColorLight,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                return Column(
                  children: [
                    items[i],
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 52,
                        endIndent: 16,
                        color: appGreyVeryLight,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SectionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppText.body(
                label,
                fontWeight: FontWeight.w700,
                size: 14,
                color: appBlack.withOpacity(0.8),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: appGreyLight),
          ],
        ),
      ),
    );
  }
}
