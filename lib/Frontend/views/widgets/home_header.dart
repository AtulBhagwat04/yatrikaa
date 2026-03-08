import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

class HomeHeader extends StatelessWidget {
  final String greeting;
  final String role;
  final String? userInitial;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.role,
    required this.onNotificationTap,
    required this.onProfileTap,
    this.userInitial,
    this.hasNewNotifications = false,
  });

  final bool hasNewNotifications;

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
                color: appGrey,
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
                color: primaryWhite.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: primaryBlue.withAlpha(51)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: primaryBlue,
                size: 22,
              ),
            ),
            if (hasNewNotifications)
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  height: 7,
                  width: 7,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: appWhite, width: 1.5),
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
            border: Border.all(color: primaryBlue.withAlpha(51)),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: primaryBlue,
            child: userInitial != null
                ? Text(
                    userInitial!.toUpperCase(),
                    style: const TextStyle(
                      color: appWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Icon(Icons.person, color: appWhite, size: 20),
          ),
        ),
      ),
    );
  }
}
