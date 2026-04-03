import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/models/travel_package_model.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/category_chip.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';

class PackagesDiscoveryScreen extends StatefulWidget {
  const PackagesDiscoveryScreen({super.key});

  @override
  State<PackagesDiscoveryScreen> createState() =>
      _PackagesDiscoveryScreenState();
}

class _PackagesDiscoveryScreenState extends State<PackagesDiscoveryScreen> {
  static const List<(String, IconData)> _tabs = [
    ('All', Icons.grid_view_rounded),
    ('Adventure', Icons.terrain_rounded),
    ('Fort Trek', Icons.castle_rounded),
    ('Spiritual', Icons.temple_hindu_rounded),
    ('Beach', Icons.beach_access_rounded),
    ('Road Trip', Icons.directions_car_rounded),
    ('Weekend Trip', Icons.weekend_rounded),
    ('Wildlife', Icons.forest_rounded),
    ('Cultural', Icons.museum_rounded),
  ];

  @override
  void initState() {
    super.initState();
    context.read<TravelBloc>().add(const TravelPackagesRequested());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: BlocBuilder<TravelBloc, TravelState>(
        builder: (ctx, state) {
          return SafeArea(
            child: RefreshIndicator(
              color: primaryBlue,
              displacement: 120,
              onRefresh: () async {
                ctx.read<TravelBloc>().add(const TravelPackagesRequested());
                await Future.delayed(const Duration(milliseconds: 700));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── Modern Header ─────────────────────────────
                  _buildHeader(ctx),

                  // ── Category chips ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: _buildTabRow(ctx, state),
                    ),
                  ),

                  // ── Package list / shimmer / empty ───────────────────────────
                  SliverToBoxAdapter(child: _buildBody(ctx, state)),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Modern header matching other screens ──────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isOrganizer =
        authState is Authenticated &&
        (authState.role == 'Organizer' || authState.role == 'Admin');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.ms, 12, AppSpacing.ms, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.heading(
                  AppStrings.packTitle,
                  fontWeight: FontWeight.w900,
                  size: 26,
                  color: appBlack,
                  letterSpacing: -0.5,
                ),
                const SizedBox(height: 2),
                AppText.caption(
                  AppStrings.packSubtitle,
                  color: appGrey,
                  fontWeight: FontWeight.w500,
                  size: 13,
                ),
              ],
            ),
            if (isOrganizer)
              _HeaderAction(
                icon: Icons.add_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.createPackage),
                isPrimary: true,
              ),
          ],
        ),
      ),
    );
  }

  // ── Category chips ──────────────────────────────────────────────────────────
  Widget _buildTabRow(BuildContext ctx, TravelState state) {
    return SizedBox(
      height: 50, // Slightly taller for breatheability
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (label, icon) = _tabs[i];
          return CategoryChip(
            label: label,
            icon: icon,
            isSelected: state.selectedCategory == label,
            onTap: () =>
                ctx.read<TravelBloc>().add(TravelCategoryChanged(label)),
          );
        },
      ),
    );
  }

  // ── Body dispatch ────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext ctx, TravelState state) {
    if (state.packagesStatus == TravelStatus.loading ||
        state.packagesStatus == TravelStatus.initial) {
      return _buildShimmerList();
    }

    if (state.packagesStatus == TravelStatus.failure) {
      return _buildError(ctx);
    }

    final packages = state.displayPackages;

    if (packages.isEmpty) {
      return _buildEmpty(ctx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.body(
                '${packages.length} Packages Found',
                color: appBlack,
                size: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              if (state.selectedCategory != 'All')
                GestureDetector(
                  onTap: () {
                    ctx.read<TravelBloc>()
                      ..add(const TravelSearchChanged(''))
                      ..add(const TravelCategoryChanged('All'));
                  },
                  child: AppText.caption(
                    'Clear All',
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                    size: 12,
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: packages.length,
          itemBuilder: (_, i) {
            return AppAnimations.fadeIn(
              duration: Duration(milliseconds: 300 + (i * 100)),
              child: _PackageCard(package: packages[i]),
            );
          },
        ),
      ],
    );
  }

  // ── Shimmer skeletons ────────────────────────────────────────────────────────
  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 270,
            child: const ShimmerBox(radius: 18),
          ),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.luggage_rounded,
              color: primaryBlue,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          AppText.heading(
            'No Packages Found',
            size: 20,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(height: 8),
          AppText.body(
            'Try a different category or search term.',
            align: TextAlign.center,
            color: appGrey,
            size: 13,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ctx.read<TravelBloc>()
                  ..add(const TravelSearchChanged(''))
                  ..add(const TravelCategoryChanged('All'));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: primaryBlue.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: appGreyLight),
            const SizedBox(height: 16),
            AppText.subHeading(
              'Could not load packages',
              size: 15,
              fontWeight: FontWeight.w700,
              color: appGrey,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ctx.read<TravelBloc>().add(const TravelPackagesRequested()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Package Card
// ─────────────────────────────────────────────────────────────────────────────
class _PackageCard extends StatelessWidget {
  final TravelPackageModel package;
  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(package.difficulty);
    final seatsLeft = package.maxGroupSize - package.currentParticipants;
    final isFull = seatsLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                RouteNames.packageDetails,
                arguments: package.id,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image ──────────────────────────────────────────────
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: package.mainPhotoUrl,
                      height: 180, // Slightly shorter
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ShimmerBox(height: 180),
                      errorWidget: (_, __, ___) => Container(
                        height: 180,
                        color: onboardingBlueVeryLight,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: appGreyLight,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                    // Simple bottom gradient for readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Seats left pill (bottom-right) ────────
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isFull
                              ? Colors.red.shade700
                              : Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFull ? 'Fully Booked' : '$seatsLeft seats left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Card body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A2E),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Location & Rating
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: appGrey,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: AppText.caption(
                                        package.destinationName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        color: appGrey,
                                        size: 11,
                                      ),
                                    ),
                                    if (package.averageRating > 0) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: ratingColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        package.averageRating.toStringAsFixed(
                                          1,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: appGreyDark,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${package.price.toInt()}',
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Text(
                                'per person',
                                style: TextStyle(
                                  color: appGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Stats Row
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.schedule_outlined,
                            label: '${package.days}D / ${package.nights}N',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.bar_chart_rounded,
                            label: package.difficulty,
                            color: diffColor,
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: appGreyLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy':
        return const Color(0xFF2DC653);
      case 'Moderate':
        return const Color(0xFFE9A21B);
      case 'Hard':
        return const Color(0xFFFF6B35);
      case 'Very Hard':
      case 'Expert':
        return const Color(0xFFE83A5A);
      default:
        return appGrey;
    }
  }
}

// Stat chip for difficulty / group size
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = appGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary ? primaryBlue : appWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? primaryBlue : appBlack).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: isPrimary ? appWhite : primaryBlue, size: 24),
      ),
    );
  }
}
