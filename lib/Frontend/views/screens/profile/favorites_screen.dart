import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';

class FavoritesScreen extends StatelessWidget {
  final bool showBackButton;

  /// Called when the "Go Explore" button is tapped inside a nav tab context.
  /// When null and showBackButton=true, falls back to Navigator.pop.
  final VoidCallback? onGoExplore;

  const FavoritesScreen({
    super.key,
    this.showBackButton = true,
    this.onGoExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: showBackButton
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: appBlack,
                  size: 20,
                ),
              )
            : null,
        automaticallyImplyLeading: false,
        title: AppText.heading(
          'Saved Places',
          fontWeight: FontWeight.w900,
          size: 20,
        ),
        centerTitle: true,
      ),
      body: AppAnimations.fadeIn(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.ms),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildEmptyUI()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          AppText.heading(
            'No Saved Places',
            size: 22,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(height: 12),
          AppText.body(
            'Explore amazing destinations and save your favorites to plan your next adventure!',
            align: TextAlign.center,
            color: Colors.grey.shade500,
            size: 14,
          ),
          const SizedBox(height: 40),
          _buildExploreButton(),
        ],
      ),
    );
  }

  Widget _buildExploreButton() {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (onGoExplore != null) {
                onGoExplore!();
              } else if (showBackButton) {
                Navigator.maybePop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: primaryBlue.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Go Explore',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
