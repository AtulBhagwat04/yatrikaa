import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          'Help Center',
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
            _buildPopularHeader().animate().fadeIn(),
            const SizedBox(height: 12),
            _buildFAQList(
              context,
            ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
            const SizedBox(height: 24),
            _buildContactCard()
                .animate()
                .fadeIn(delay: 400.ms)
                .scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(
            'Frequently Asked Questions',
            fontWeight: FontWeight.w900,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Column(
        children: [
          _buildFAQItem(
            context,
            'How do I create a travel itinerary?',
            'Go to the "Explore" tab, select your preferred destination, and use the "Plan Trip" button to build a custom day-by-day schedule.',
          ),
          _buildFAQItem(
            context,
            'Are the local guides verified?',
            'Yes, every guide on Yatrikaa undergoes a strict verification process including identity checks and travel knowledge assessment to ensure your safety.',
          ),
          _buildFAQItem(
            context,
            'How can I find hidden or offbeat places?',
            'In the Explore section, look for the "Unseen Bharat" category. We curate these locations specifically for travelers seeking unique experiences.',
          ),
          _buildFAQItem(
            context,
            'Can I share my live trip status?',
            'Once your trip starts, you can use the "Share Journey" feature in your itinerary to send a live tracking link to your family for security.',
          ),
          _buildFAQItem(
            context,
            'What if I face an issue during a trip?',
            'You can immediately use the "Contact Support" button in the Help Center or call our 24/7 dedicated travel support line.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: AppText.body(question, fontWeight: FontWeight.w700, size: 14),
          iconColor: primaryBlue,
          collapsedIconColor: appGreyLight,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            AppText.body(
              answer,
              size: 13,
              color: appBlack.withOpacity(0.6),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appWhite.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.headset_mic_rounded,
                    color: appWhite,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        'Need direct help?',
                        color: appWhite,
                        fontWeight: FontWeight.w900,
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      AppText.caption(
                        'Our team is available 24/7 for you',
                        color: appWhite.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: appWhite,
                  foregroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  elevation: 0,
                ),
                child: AppText.body(
                  'Contact Support Now',
                  fontWeight: FontWeight.w900,
                  size: 14,
                  color: primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
