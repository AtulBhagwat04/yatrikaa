import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';

class GuideDashboardScreen extends StatelessWidget {
  const GuideDashboardScreen({super.key});

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
          'Guide Dashboard',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            const SizedBox(height: AppSpacing.l),
            AppText.body('Active Tours', fontWeight: FontWeight.bold),
            const SizedBox(height: AppSpacing.m),
            _buildEmptyState(
              'No active tours',
              'Create your first tour package to start receiving bookings!',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppText.body('Recent Bookings', fontWeight: FontWeight.bold),
            const SizedBox(height: AppSpacing.m),
            _buildEmptyState(
              'No recent bookings',
              'Your booking requests will appear here once travelers book your tours.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statItem(
          'Total Earnings',
          '₹0',
          Icons.account_balance_wallet_outlined,
          const Color(0xFFEA580C),
        ),
        const SizedBox(width: 12),
        _statItem('Rating', '5.0', Icons.star_outline_rounded, Colors.orange),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            AppText.heading(value, size: 20),
            AppText.caption(label, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey.shade300, size: 40),
          const SizedBox(height: 12),
          AppText.body(title, fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          AppText.caption(
            subtitle,
            align: TextAlign.center,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
