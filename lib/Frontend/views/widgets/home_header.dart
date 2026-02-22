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
        Stack(
          clipBehavior: Clip.none,
          children: [
            _profileButton(),
            Positioned(bottom: -4, right: -4, child: _roleBadge()),
          ],
        ),
      ],
    );
  }

  Widget _roleBadge() {
    Color badgeColor = primaryBlue;
    if (role.toLowerCase() == 'admin' || role.toLowerCase() == 'super-admin') {
      badgeColor = Colors.redAccent;
    }
    if (role.toLowerCase() == 'guide') badgeColor = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
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
            border: Border.all(color: primaryBlue.withAlpha(51)),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: primaryBlue,
            child: userInitial != null
                ? Text(
                    userInitial!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
