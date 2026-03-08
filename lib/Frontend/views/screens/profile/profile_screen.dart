import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_event.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';

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
  final r = role.toLowerCase();
  switch (r) {
    case 'super-admin':
      return const _RoleConfig(
        label: 'Super Admin',
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFF7C3AED),
      );
    case 'admin':
      return const _RoleConfig(
        label: 'Admin',
        icon: Icons.verified_user_rounded,
        color: Color(0xFFDC2626),
      );
    case 'guide':
      return const _RoleConfig(
        label: 'Verified Guide',
        icon: Icons.verified_rounded,
        color: Color(0xFF059669),
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
          appBar: AppBar(
            backgroundColor: onboardingBlueVeryLight,
            elevation: 0,
            scrolledUnderElevation: 2,
            surfaceTintColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: showBackButton
                ? IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: appBlack,
                      size: 20,
                    ),
                  )
                : null,
            automaticallyImplyLeading: false,
            title: AppText.heading(
              authState.name.isEmpty ? 'Profile' : authState.name,
              fontWeight: FontWeight.w900,
              size: 20,
            ),
            centerTitle: true,
            actions: [const SizedBox(width: 8)],
          ),
          body: AppAnimations.fadeIn(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Profile Card ─────────────────────────
                SliverToBoxAdapter(
                  child: _ProfileCard(state: authState, cfg: cfg),
                ),

                // ── Stats ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.ms,
                    ),
                    child: _StatsRow(state: authState),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Account Settings ─────────────────────
                SliverToBoxAdapter(
                  child: _SectionGroup(
                    heading: 'Account',
                    items: [
                      _SectionItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        color: primaryBlue,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.editProfile,
                        ),
                      ),
                      _SectionItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        color: primaryBlue,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.changePassword,
                        ),
                      ),
                      _SectionItem(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        color: primaryBlue,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.notifications,
                        ),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Travel ───────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionGroup(
                    heading: 'Travel',
                    items: [
                      _SectionItem(
                        icon: Icons.grid_view_rounded,
                        label: 'My Posts',
                        color: const Color(0xFF059669),
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.myPosts),
                      ),
                      _SectionItem(
                        icon: Icons.map_outlined,
                        label: 'My Trips',
                        color: const Color(0xFF059669),
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.trips),
                      ),
                      _SectionItem(
                        icon: Icons.favorite_border_rounded,
                        label: 'Liked Places',
                        color: const Color(0xFF059669),
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.favorites),
                      ),
                      _SectionItem(
                        icon: Icons.star_border_rounded,
                        label: 'My Reviews',
                        color: const Color(0xFF059669),
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.reviews),
                      ),
                    ],
                  ),
                ),

                // ── Role-based sections ───────────────────
                ..._roleSections(authState.role, context),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Support ──────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionGroup(
                    heading: 'Support',
                    items: [
                      _SectionItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help Center',
                        color: const Color(0xFF7C3AED),
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.helpCenter),
                      ),
                      _SectionItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        color: const Color(0xFF7C3AED),
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.privacyPolicy,
                        ),
                      ),
                      _SectionItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About Bhatkanti',
                        color: const Color(0xFF7C3AED),
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.about),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Logout ───────────────────────────────
                SliverToBoxAdapter(
                  child: _LogoutTile(onTap: () => _showLogoutDialog(context)),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SliverToBoxAdapter> _roleSections(String role, BuildContext context) {
    final r = role.toLowerCase();
    List<SliverToBoxAdapter> out = [];

    if (r == 'guide' || r == 'admin' || r == 'super-admin') {
      out.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
      out.add(
        SliverToBoxAdapter(
          child: _SectionGroup(
            heading: 'Guide Panel',
            items: [
              _SectionItem(
                icon: Icons.dashboard_outlined,
                label: 'Guide Dashboard',
                color: const Color(0xFFEA580C),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.guideDashboard),
              ),
              _SectionItem(
                icon: Icons.tour_rounded,
                label: 'Manage Tours',
                color: const Color(0xFFEA580C),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.manageTours),
              ),
              _SectionItem(
                icon: Icons.calendar_today_outlined,
                label: 'Booking Requests',
                color: const Color(0xFFEA580C),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.bookingRequests),
              ),
            ],
          ),
        ),
      );
    }

    if (r == 'admin' || r == 'super-admin') {
      out.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
      out.add(
        SliverToBoxAdapter(
          child: _SectionGroup(
            heading: 'Admin Tools',
            items: [
              _SectionItem(
                icon: Icons.add_location_alt_outlined,
                label: 'Manage Places',
                color: const Color(0xFFDC2626),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.managePlaces),
              ),
              _SectionItem(
                icon: Icons.calendar_month_outlined,
                label: 'Manage Events',
                color: const Color(0xFFDC2626),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.manageEvents),
              ),
              _SectionItem(
                icon: Icons.rate_review_outlined,
                label: 'Review Moderation',
                color: const Color(0xFFDC2626),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.reviewModeration),
              ),
            ],
          ),
        ),
      );
    }

    if (r == 'super-admin') {
      out.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
      out.add(
        SliverToBoxAdapter(
          child: _SectionGroup(
            heading: 'System Authority',
            items: [
              _SectionItem(
                icon: Icons.people_alt_outlined,
                label: 'User Management',
                color: const Color(0xFF7C3AED),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.userManagement),
              ),
              _SectionItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.pushNamed(context, RouteNames.analytics),
              ),
              _SectionItem(
                icon: Icons.tune_rounded,
                label: 'System Config',
                color: const Color(0xFF7C3AED),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.systemConfig),
              ),
            ],
          ),
        ),
      );
    }

    return out;
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            AppText.body('Sign Out', fontWeight: FontWeight.w700),
          ],
        ),
        content: AppText.caption(
          'Are you sure you want to sign out of Bhatkanti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: AppText.caption(
              'Cancel',
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LoggedOut());
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.login,
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: AppText.button('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Card (compact, professional) ───────────────────────
class _ProfileCard extends StatelessWidget {
  final Authenticated state;
  final _RoleConfig cfg;

  const _ProfileCard({required this.state, required this.cfg});

  @override
  Widget build(BuildContext context) {
    final name = state.name.trim();
    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Gradient header strip ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [onboardingBlue, onboardingBlueSoft],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.7),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: AppText.heading(
                      firstChar,
                      color: Colors.white,
                      size: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.subHeading(
                        state.name.isEmpty ? 'Traveler' : state.name,
                        color: Colors.white,
                        size: 17,
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      AppText.caption(
                        state.email,
                        color: Colors.white.withOpacity(0.75),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Role badge strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cfg.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cfg.icon, size: 13, color: cfg.color),
                ),
                const SizedBox(width: 8),
                AppText.caption(
                  cfg.label,
                  color: cfg.color,
                  fontWeight: FontWeight.w700,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryBlue.withOpacity(0.18)),
                  ),
                  child: AppText.small(
                    'Member',
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Authenticated state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatCell(
            icon: Icons.grid_view_rounded,
            value: '${state.postsCount}',
            label: 'Posts',
            color: primaryBlue,
            onTap: () => Navigator.pushNamed(context, RouteNames.myPosts),
          ),
          _verticalDivider(),
          _StatCell(
            icon: Icons.favorite_border_rounded,
            value: '${state.savedCount}',
            label: 'Likes',
            color: const Color(0xFF059669),
            onTap: () => Navigator.pushNamed(context, RouteNames.favorites),
          ),
          _verticalDivider(),
          _StatCell(
            icon: Icons.star_border_rounded,
            value: '${state.reviewsCount}',
            label: 'Reviews',
            color: const Color(0xFFFBBF24),
            onTap: () => Navigator.pushNamed(context, RouteNames.reviews),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() =>
      Container(width: 1, height: 36, color: const Color(0xFFE5E7EB));
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              AppText.body(
                value,
                fontWeight: FontWeight.w800,
                color: color,
                size: 16,
              ),
              AppText.small(
                label,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Group ───────────────────────────────────────────────
class _SectionGroup extends StatelessWidget {
  final String heading;
  final List<_SectionItem> items;

  const _SectionGroup({required this.heading, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: AppText.caption(
              heading.toUpperCase(),
              color: Colors.grey,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              size: 11,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                return Column(
                  children: [
                    items[i],
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 52,
                        endIndent: 16,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Item ────────────────────────────────────────────────
class _SectionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SectionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppText.body(
                  label,
                  fontWeight: FontWeight.w600,
                  size: 14,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logout Tile ─────────────────────────────────────────────────
class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppText.body(
                    'Sign Out',
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    size: 15,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.redAccent.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
