import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          'Help Center',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          _buildSearchBar(),
          const SizedBox(height: AppSpacing.l),
          AppText.body(
            'Frequently Asked Questions',
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: AppSpacing.m),
          _buildFAQTile(
            'How do I book a guide?',
            'You can book a guide by browsing the guide list in the explore tab and selecting "Book Now" on their profile.',
          ),
          _buildFAQTile(
            'How can I save a place?',
            'Tap the heart icon on any place card to add it to your saved places list in your profile.',
          ),
          _buildFAQTile(
            'Can I plan a trip with friends?',
            'Yes, you can create a group trip and invite your friends using their email addresses.',
          ),
          _buildFAQTile(
            'How do I become a guide?',
            'To become a guide, you need to apply through the "Be a Guide" section and undergo a verification process.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildContactSupport(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search for help...',
          icon: const Icon(Icons.search_rounded, color: primaryBlue),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: AppText.body(question, fontWeight: FontWeight.w600, size: 14),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          AppText.body(
            answer,
            size: 13,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [onboardingBlue, onboardingBlueSoft],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          AppText.body(
            'Still need help?',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          AppText.caption(
            'Our team is here to assist you 24/7',
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}
