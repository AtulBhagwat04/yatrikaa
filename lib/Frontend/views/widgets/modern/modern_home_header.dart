import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';

class ModernHomeHeader extends StatelessWidget {
  final String greeting;
  final String? userName;
  final String? location;
  final bool hasNewNotifications;
  final VoidCallback onNotificationTap;

  const ModernHomeHeader({
    super.key,
    required this.greeting,
    this.userName,
    this.location,
    this.hasNewNotifications = false,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Greeting and Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppText.body(
                    "$greeting, ${userName ?? 'Traveler'}!",
                    fontWeight: FontWeight.w600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text("👋", style: TextStyle(fontSize: 16)),
                ],
              ),
              if (location != null)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: appGreyDark,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    AppText.caption(
                      location!,
                      color: appGreyDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Notification Bell
        Material(
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: appBlack,
                    size: 24,
                  ),
                ),
                if (hasNewNotifications)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: appWhite, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
