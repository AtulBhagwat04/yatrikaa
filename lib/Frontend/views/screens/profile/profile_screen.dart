import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_event.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/core/services/packages_service.dart';
import 'package:yatrikaa/Frontend/views/widgets/custom_alert_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Role configuration model ───────────────────────────────────
class _RoleConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _RoleConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

_RoleConfig _roleConfig(String role) {
  final r = role.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (r) {
    case 'admin':
    case 'superadmin':
      return _RoleConfig(
        label: r == 'admin' ? 'Admin' : 'Super Admin',
        icon: Icons.admin_panel_settings_rounded,
        color: adminColor,
      );
    case 'guide':
      return const _RoleConfig(
        label: 'Verified Guide',
        icon: Icons.verified_rounded,
        color: guideColor,
      );
    default:
      return const _RoleConfig(
        label: 'Explorer',
        icon: Icons.explore_rounded,
        color: primaryBlue,
      );
  }
}

// ─── Profile Screen ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return Scaffold(
            backgroundColor: onboardingBlueVeryLight,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final cfg = _roleConfig(authState.role);

        return Scaffold(
          backgroundColor: onboardingBlueVeryLight,
          body: AppAnimations.fadeIn(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Compact Header ──
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor: onboardingBlueVeryLight,
                  elevation: 0,
                  scrolledUnderElevation: 2,
                  surfaceTintColor: Colors.white,
                  automaticallyImplyLeading: false,
                  centerTitle: true,
                  title: AppText.heading(
                    'My Profile',
                    fontWeight: FontWeight.w900,
                    size: 22,
                  ),
                ),
                // ── Profile Header ──
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    state: authState,
                    cfg: cfg,
                  ).animate().fadeIn().moveY(begin: 20, end: 0),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                // ── Stats Summary ──
                SliverToBoxAdapter(
                  child: _StatsSummary(state: authState)
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .scale(begin: const Offset(0.98, 0.98)),
                ),
                // ── Sections ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── ACCOUNT ──
                        _SectionHeader('ACCOUNT'),
                        _SectionCard(
                          items: [
                            _ProfileItem(
                              icon: Icons.person_outline_rounded,
                              label: 'Edit Profile',
                              iconBgColor: Colors.blue.withOpacity(0.1),
                              iconColor: Colors.blue,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.editProfile,
                              ),
                            ),
                            _ProfileItem(
                              icon: Icons.lock_outline_rounded,
                              label: 'Change Password',
                              iconBgColor: Colors.blue.withOpacity(0.1),
                              iconColor: Colors.blue,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.changePassword,
                              ),
                            ),
                          ],
                        ),

                        // ── TRAVEL ──
                        _SectionHeader('TRAVEL'),
                        _SectionCard(
                          items: [
                            _ProfileItem(
                              icon: Icons.grid_view_rounded,
                              label: 'My Posts',
                              iconBgColor: Colors.green.withOpacity(0.1),
                              iconColor: Colors.green,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.myPosts,
                              ),
                            ),
                            _ProfileItem(
                              icon: Icons.map_outlined,
                              label: 'My Trips',
                              iconBgColor: Colors.green.withOpacity(0.1),
                              iconColor: Colors.green,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.trips,
                              ),
                            ),
                            _ProfileItem(
                              icon: Icons.favorite_outline_rounded,
                              label: 'Liked Places',
                              iconBgColor: Colors.teal.withOpacity(0.1),
                              iconColor: Colors.teal,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.favorites,
                              ),
                            ),
                            _ProfileItem(
                              icon: Icons.star_outline_rounded,
                              label: 'My Reviews',
                              iconBgColor: Colors.teal.withOpacity(0.1),
                              iconColor: Colors.teal,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.reviews,
                              ),
                            ),
                          ],
                        ),

                        // ── ROLE SPECIFIC SECTIONS (GUIDE / ADMIN) ──
                        ..._buildRoleSections(context, authState),

                        // ── SUPPORT ──
                        _SectionHeader('SUPPORT'),
                        _SectionCard(
                          items: [
                            _ProfileItem(
                              icon: Icons.help_outline_rounded,
                              label: 'Help Center',
                              iconBgColor: Colors.deepPurple.withOpacity(0.1),
                              iconColor: Colors.deepPurple,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.helpCenter,
                              ),
                            ),
                            _ProfileItem(
                              icon: Icons.shield_outlined,
                              label: 'Privacy Policy',
                              iconBgColor: Colors.deepPurple.withOpacity(0.1),
                              iconColor: Colors.deepPurple,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.privacyPolicy,
                              ),
                            ),
                            _ProfileItem(
                              icon: Icons.info_outline_rounded,
                              label: 'About Yatrikaa',
                              iconBgColor: Colors.deepPurple.withOpacity(0.1),
                              iconColor: Colors.deepPurple,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.about,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        // ── SIGN OUT ──
                        _SectionCard(
                          items: [
                            _ProfileItem(
                              icon: Icons.logout_rounded,
                              label: 'Sign Out',
                              iconBgColor: Colors.red.withOpacity(0.1),
                              iconColor: Colors.red,
                              labelColor: Colors.redAccent,
                              showArrow: true,
                              onTap: () => _showLogoutDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRoleSections(BuildContext context, Authenticated state) {
    final r = state.role.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    List<Widget> sections = [];

    if (r == 'user' && state.guideRequestStatus != 'Pending') {
      sections.addAll([
        _SectionHeader('OPPORTUNITY'),
        _SectionCard(
          items: [
            _ProfileItem(
              icon: Icons.verified_user_outlined,
              label: 'Become a Guide',
              iconBgColor: Colors.orange.withOpacity(0.1),
              iconColor: Colors.orange,
              onTap: () => _showGuideRequestDialog(context),
            ),
          ],
        ),
      ]);
    }

    if (r == 'guide' || r == 'admin' || r == 'superadmin') {
      sections.addAll([
        _SectionHeader('GUIDE PANEL'),
        _SectionCard(
          items: [
            _ProfileItem(
              icon: Icons.flag_outlined,
              label: 'Manage Tours',
              iconBgColor: Colors.orange.withOpacity(0.1),
              iconColor: Colors.orange,
              onTap: () => Navigator.pushNamed(context, RouteNames.manageTours),
            ),
            _ProfileItem(
              icon: Icons.assignment_outlined,
              label: 'Bookings',
              iconBgColor: Colors.orange.withOpacity(0.1),
              iconColor: Colors.orange,
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.bookingRequests),
            ),
          ],
        ),
      ]);
    }

    if (r == 'admin' || r == 'superadmin') {
      sections.addAll([
        _SectionHeader('ADMIN CONTROL'),
        _SectionCard(
          items: [
            _ProfileItem(
              icon: Icons.people_outline_rounded,
              label: 'User Management',
              iconBgColor: Colors.red.withOpacity(0.05),
              iconColor: Colors.red,
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.userManagement),
            ),
            _ProfileItem(
              icon: Icons.add_location_alt_outlined,
              label: 'Manage Places',
              iconBgColor: Colors.red.withOpacity(0.05),
              iconColor: Colors.red,
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.managePlaces),
            ),
            _ProfileItem(
              icon: Icons.calendar_today_outlined,
              label: 'Manage Events',
              iconBgColor: Colors.red.withOpacity(0.05),
              iconColor: Colors.red,
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.manageEvents),
            ),
            _ProfileItem(
              icon: Icons.rate_review_outlined,
              label: 'Review Moderation',
              iconBgColor: Colors.red.withOpacity(0.05),
              iconColor: Colors.red,
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.reviewModeration),
            ),
            _ProfileItem(
              icon: Icons.checklist_rtl_rounded,
              label: 'Global Approval Queue',
              iconBgColor: Colors.red.withOpacity(0.05),
              iconColor: Colors.red,
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.adminApprovalQueue),
            ),
          ],
        ),
      ]);
    }

    return sections;
  }

  void _showLogoutDialog(BuildContext context) {
    CustomAlertDialog.show(
      context,
      title: 'Sign Out',
      message: 'Take a break, Yatrikaa will miss you! Come back soon.',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Stay',
      type: CustomAlertType.error,
      icon: Icons.logout_rounded,
      onConfirm: () {
        context.read<AuthBloc>().add(LoggedOut());
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.login,
          (_) => false,
        );
      },
    );
  }

  void _showGuideRequestDialog(BuildContext context) {
    CustomAlertDialog.show(
      context,
      title: 'Share your Expertise',
      message:
          'Apply to become a verified guide and help others explore the soul of Bharat.',
      confirmLabel: 'Apply Now',
      cancelLabel: 'Later',
      type: CustomAlertType.info,
      icon: Icons.verified_rounded,
      onConfirm: () async {
        final success = await PackagesService().requestGuideRole();
        if (success && context.mounted) {
          context.read<AuthBloc>().add(AppStarted());
          CustomToast.success(context, 'Application submitted!');
        }
      },
    );
  }
}

// ─── Visual Components ───

class _ProfileHeader extends StatelessWidget {
  final Authenticated state;
  final _RoleConfig cfg;
  const _ProfileHeader({required this.state, required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: appWhite,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: primaryBlue.withOpacity(0.1),
              child:
                  state.profilePicture != null &&
                      state.profilePicture!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: state.profilePicture!,
                        width: 108,
                        height: 108,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => AppText.heading(
                          state.name.isNotEmpty
                              ? state.name[0].toUpperCase()
                              : '?',
                          size: 40,
                          color: primaryBlue,
                        ),
                      ),
                    )
                  : AppText.heading(
                      state.name.isNotEmpty ? state.name[0].toUpperCase() : '?',
                      size: 40,
                      color: primaryBlue,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          AppText.heading(state.name, size: 22, fontWeight: FontWeight.w900),
          const SizedBox(height: 2),
          AppText.caption(
            state.email,
            color: appGrey,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  final Authenticated state;
  const _StatsSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: appBlack.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              label: 'Posts',
              value: state.postsCount.toString(),
              color: primaryBlue,
            ),
            _vDivider(),
            _StatItem(
              label: 'Favorites',
              value: state.savedCount.toString(),
              color: Colors.pinkAccent,
            ),
            _vDivider(),
            _StatItem(
              label: 'Reviews',
              value: state.reviewsCount.toString(),
              color: Colors.orangeAccent,
            ),
            _vDivider(),
            _StatItem(
              label: 'Trips',
              value: state.tripsCount.toString(),
              color: travelSectionColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() =>
      Container(height: 30, width: 1, color: appGreyVeryLight);
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText.heading(
          value,
          size: 18,
          fontWeight: FontWeight.w900,
          color: color,
        ),
        const SizedBox(height: 2),
        AppText.caption(
          label,
          size: 11,
          color: appGrey,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 12),
      child: AppText.body(
        title,
        size: 11,
        fontWeight: FontWeight.w800,
        color: appGrey,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> items;
  const _SectionCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: appBlack.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index < items.length - 1)
                Divider(height: 1, thickness: 1, color: appGreyLight),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconBgColor;
  final Color iconColor;
  final Color? labelColor;
  final bool showArrow;

  const _ProfileItem({
    required this.icon,
    required this.label,
    this.onTap,
    required this.iconBgColor,
    required this.iconColor,
    this.labelColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppText.body(
                label,
                fontWeight: FontWeight.w600,
                size: 14,
                color: labelColor ?? appBlack,
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: appGrey.withOpacity(0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
