import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

class HomeHeader extends StatelessWidget {
  final String greeting;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                greeting,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                align: TextAlign.left,
              ),
              const SizedBox(height: 4),
              AppText.body(
                AppStrings.whereToExplore,
                align: TextAlign.left,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
        _notificationButton(),
        const SizedBox(width: 12),
        _profileButton(),
      ],
    );
  }

  Widget _notificationButton() {
    bool hasNotification = true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          HapticFeedback.lightImpact();
          onNotificationTap();
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryWhite.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: primaryBlue.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: primaryBlue,
                size: 22,
              ),
            ),
            if (hasNotification)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          HapticFeedback.lightImpact();
          onProfileTap();
        },
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryBlue.withOpacity(0.2)),
          ),
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: primaryWhite,
            child: Icon(Icons.person, color: primaryBlue, size: 20),
          ),
        ),
      ),
    );
  }
}
