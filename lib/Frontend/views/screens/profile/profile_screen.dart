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
          appBar: AppBar(
            backgroundColor: onboardingBlueVeryLight,
            elevation: 0,
            scrolledUnderElevation: 2,
            surfaceTintColor: appWhite,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
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
                        color: travelSectionColor,
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.myPosts),
                      ),
                      _SectionItem(
                        icon: Icons.map_outlined,
                        label: 'My Trips',
                        color: travelSectionColor,
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.trips),
                      ),
                      _SectionItem(
                        icon: Icons.favorite_border_rounded,
                        label: 'Liked Places',
                        color: travelSectionColor,
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.favorites),
                      ),
                      _SectionItem(
                        icon: Icons.star_border_rounded,
                        label: 'My Reviews',
                        color: travelSectionColor,
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.reviews),
                      ),
                    ],
                  ),
                ),

                // ── Role-based sections ───────────────────
                ..._roleSections(
                  authState.role,
                  authState.guideRequestStatus,
                  context,
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Support ──────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionGroup(
                    heading: 'Support',
                    items: [
                      _SectionItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help Center',
                        color: supportSectionColor,
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.helpCenter),
                      ),
                      _SectionItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        color: supportSectionColor,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.privacyPolicy,
                        ),
                      ),
                      _SectionItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About Yatrikaa',
                        color: supportSectionColor,
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

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl + AppSpacing.l),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SliverToBoxAdapter> _roleSections(
    String role,
    String guideStatus,
    BuildContext context,
  ) {
    final r = role.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    List<SliverToBoxAdapter> out = [];

    // Traveler level - Request to be a Guide
    if (r == 'user') {
      out.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));

      String label = 'Join as Guide';
      IconData icon = Icons.person_add_alt_1_rounded;
      Color color = guideColor;
      VoidCallback? onTap = () => _showGuideRequestDialog(context);

      if (guideStatus == 'Pending') {
        label = 'Guide Request Pending';
        icon = Icons.hourglass_top_rounded;
        color = appGrey;
        onTap = null;
      } else if (guideStatus == 'Rejected') {
        label = 'Re-apply for Guide';
      }

      out.add(
        SliverToBoxAdapter(
          child: _SectionGroup(
            heading: 'Opportunity',
            items: [
              _SectionItem(
                icon: icon,
                label: label,
                color: color,
                onTap: onTap,
              ),
            ],
          ),
        ),
      );
    }

    if (r == 'guide' || r == 'admin' || r == 'superadmin') {
      out.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
      out.add(
        SliverToBoxAdapter(
          child: _SectionGroup(
            heading: 'Guide Panel',
            items: [
              _SectionItem(
                icon: Icons.tour_rounded,
                label: 'Manage Tours',
                color: guidePanelColor,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.manageTours),
              ),
              _SectionItem(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Bookings',
                color: guidePanelColor,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.bookingRequests),
              ),
            ],
          ),
        ),
      );
    }

    if (r == 'admin' || r == 'superadmin') {
      out.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
      out.add(
        SliverToBoxAdapter(
          child: _SectionGroup(
            heading: 'Admin Control',
            items: [
              _SectionItem(
                icon: Icons.people_alt_outlined,
                label: 'User Management',
                color: adminColor,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.userManagement),
              ),
              _SectionItem(
                icon: Icons.add_location_alt_outlined,
                label: 'Manage Places',
                color: adminColor,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.managePlaces),
              ),
              _SectionItem(
                icon: Icons.calendar_month_outlined,
                label: 'Manage Events',
                color: adminColor,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.manageEvents),
              ),
              _SectionItem(
                icon: Icons.rate_review_outlined,
                label: 'Review Moderation',
                color: adminColor,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.reviewModeration),
              ),
              _SectionItem(
                icon: Icons.checklist_rtl_rounded,
                label: 'Global Approval Queue',
                color: adminColor,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.adminApprovalQueue),
              ),
            ],
          ),
        ),
      );
    }

    return out;
  }

  void _showLogoutDialog(BuildContext context) {
    CustomAlertDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of Yatrikaa?',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Cancel',
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
      title: 'Become a Guide',
      message:
          'Our admin will review your profile and approve you within 24-48 hours.',
      confirmLabel: 'Send Request',
      cancelLabel: 'Later',
      type: CustomAlertType.info,
      icon: Icons.person_add_rounded,
      onConfirm: () async {
        final success = await PackagesService().requestGuideRole();
        if (success && context.mounted) {
          context.read<AuthBloc>().add(AppStarted());
          CustomToast.success(context, 'Guide request sent successfully!');
        }
      },
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
        color: appWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [onboardingBlue, onboardingBlueSoft],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: appWhite.withAlpha(178),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: appWhite.withAlpha(51),
                    child:
                        state.profilePicture != null &&
                            state.profilePicture!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: state.profilePicture!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: appWhite,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  AppText.heading(
                                    firstChar,
                                    color: appWhite,
                                    size: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          )
                        : AppText.heading(
                            firstChar,
                            color: appWhite,
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
                        color: appWhite,
                        size: 17,
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      AppText.caption(
                        state.email,
                        color: appWhite.withAlpha(191),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
        color: appWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
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
            color: travelSectionColor,
            onTap: () => Navigator.pushNamed(context, RouteNames.favorites),
          ),
          _verticalDivider(),
          _StatCell(
            icon: Icons.star_border_rounded,
            value: '${state.reviewsCount}',
            label: 'Reviews',
            color: reviewStatColor,
            onTap: () => Navigator.pushNamed(context, RouteNames.reviews),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() =>
      Container(width: 1, height: 36, color: appGreyVeryLight);
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
              AppText.small(label, color: appGrey, fontWeight: FontWeight.w500),
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
              color: appGrey,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              size: 11,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: appWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColorLight,
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
                        color: appGreyVeryLight,
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
  final VoidCallback? onTap;

  const _SectionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
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
              Icon(Icons.chevron_right_rounded, size: 18, color: appGreyLight),
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
              border: Border.all(color: errorColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: errorColorLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: errorColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppText.body(
                    'Sign Out',
                    color: errorColor,
                    fontWeight: FontWeight.w600,
                    size: 15,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: errorColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
