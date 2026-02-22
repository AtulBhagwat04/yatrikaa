import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _tripReminders = true;
  bool _bookingUpdates = true;
  bool _promotions = false;

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
          'Notifications',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          _buildHeader('General'),
          _buildToggleTile(
            'Push Notifications',
            'Receive alerts on your device',
            _pushNotifications,
            (val) => setState(() => _pushNotifications = val),
          ),
          _buildToggleTile(
            'Email Notifications',
            'Receive updates via email',
            _emailNotifications,
            (val) => setState(() => _emailNotifications = val),
          ),
          const SizedBox(height: AppSpacing.l),
          _buildHeader('Activities'),
          _buildToggleTile(
            'Trip Reminders',
            'Alerts for upcoming trips',
            _tripReminders,
            (val) => setState(() => _tripReminders = val),
          ),
          _buildToggleTile(
            'Booking Updates',
            'Stay updated on your booking status',
            _bookingUpdates,
            (val) => setState(() => _bookingUpdates = val),
          ),
          const SizedBox(height: AppSpacing.l),
          _buildHeader('Promotional'),
          _buildToggleTile(
            'Offers & Promotions',
            'Get notified about discounts and deals',
            _promotions,
            (val) => setState(() => _promotions = val),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.s),
      child: AppText.caption(
        title.toUpperCase(),
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: primaryBlue,
        title: AppText.body(title, fontWeight: FontWeight.w700),
        subtitle: AppText.caption(subtitle, size: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
