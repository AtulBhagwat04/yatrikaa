import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/models/travel_package_model.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/category_chip.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';

class PackagesDiscoveryScreen extends StatefulWidget {
  const PackagesDiscoveryScreen({super.key});

  @override
  State<PackagesDiscoveryScreen> createState() =>
      _PackagesDiscoveryScreenState();
}

class _PackagesDiscoveryScreenState extends State<PackagesDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: BlocBuilder<TravelBloc, TravelState>(
        builder: (ctx, state) {
          return RefreshIndicator(
            color: primaryBlue,
            displacement: 120,
            onRefresh: () async {
              ctx.read<TravelBloc>().add(const TravelPackagesRequested());
              await Future.delayed(const Duration(milliseconds: 700));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                // ── Collapsible gradient header ─────────────────────────────
                _buildSliverHeader(),

                // ── Search bar ──────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                      child: _buildSearchBar(ctx, state)),
                ),

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
          );
        },
      ),
    );
  }

  // ── Sliver header with gradient ─────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: false,
      pinned: true,
      snap: false,
      automaticallyImplyLeading: false,
      backgroundColor: primaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Travel Packages',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Curated trips across Maharashtra',
              style: TextStyle(
                color: Colors.white.withOpacity(0.80),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0), // Deep blue
                Color(0xFF1E88E5), // primaryBlue
                Color(0xFF42A5F5), // Lighter blue
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 18),
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.luggage_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext ctx, TravelState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (q) {
          setState(() => _searchQuery = q);
          ctx.read<TravelBloc>().add(TravelSearchChanged(q));
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: 'Search packages, destinations...',
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: primaryBlue, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: appGrey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    ctx
                        .read<TravelBloc>()
                        .add(const TravelSearchChanged(''));
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // ── Category chips ──────────────────────────────────────────────────────────
  Widget _buildTabRow(BuildContext ctx, TravelState state) {
    return SizedBox(
      height: 45,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            AppText.body(
              '${packages.length} package${packages.length == 1 ? '' : 's'} found',
              color: const Color(0xFF1A1A2E),
              size: 13,
              fontWeight: FontWeight.w700,
            ),
          ]),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: packages.length,
          itemBuilder: (_, i) => _PackageCard(package: packages[i]),
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
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.luggage_rounded, color: primaryBlue, size: 48),
        ),
        const SizedBox(height: 20),
        AppText.heading('No Packages Found',
            size: 20, fontWeight: FontWeight.w900),
        const SizedBox(height: 8),
        AppText.body('Try a different category or search term.',
            align: TextAlign.center, color: appGrey, size: 13),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
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
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Clear Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: appGreyLight),
          const SizedBox(height: 16),
          AppText.subHeading('Could not load packages',
              size: 15, fontWeight: FontWeight.w700, color: appGrey),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ctx
                .read<TravelBloc>()
                .add(const TravelPackagesRequested()),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, foregroundColor: Colors.white),
          ),
        ]),
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
    final isAlmostFull = seatsLeft <= 5 && seatsLeft > 0;
    final isFull = seatsLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, RouteNames.packageDetails,
                  arguments: package.id);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image ──────────────────────────────────────────────
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: package.mainPhotoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ShimmerBox(height: 200),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: onboardingBlueVeryLight,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              color: appGreyLight, size: 40),
                        ),
                      ),
                    ),

                    // Full gradient scrim — readable badges guaranteed
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.35, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Rating pill (top-right) ───────────────────────────────
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _Pill(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded,
                              color: ratingColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            package.averageRating > 0
                                ? package.averageRating.toStringAsFixed(1)
                                : 'New',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                    ),

                    // ── Seats left pill (top-left) — only when notable ────────
                    if (isAlmostFull || isFull)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isFull
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isFull ? 'Fully Booked' : '$seatsLeft seats left',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    // ── Category + duration row (bottom of image) ─────────────
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            package.category.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5),
                          ),
                        ),
                        const Spacer(),
                        // Duration badge
                        _Pill(
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_outlined,
                                    size: 11, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${package.days}D / ${package.nights}N',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700),
                                ),
                              ]),
                        ),
                      ]),
                    ),
                  ],
                ),

                // ── Card body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + chevron
                      Row(children: [
                        Expanded(
                          child: Text(
                            package.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: appGreyLight),
                      ]),
                      const SizedBox(height: 6),

                      // Location
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: appGrey, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppText.caption(
                            package.destinationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            color: appGrey,
                          ),
                        ),
                      ]),

                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 12),

                      // Stats + Price
                      Row(children: [
                        // Group size
                        _InfoChip(
                          icon: Icons.people_outline_rounded,
                          label: 'Max ${package.maxGroupSize}',
                        ),
                        const SizedBox(width: 8),
                        // Difficulty
                        _InfoChip(
                          icon: Icons.bar_chart_rounded,
                          label: package.difficulty,
                          color: diffColor,
                        ),
                        const Spacer(),
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${package.price.toInt()}',
                              style: const TextStyle(
                                color: primaryBlue,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'per person',
                              style: TextStyle(
                                  color: appGrey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ]),
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
      case 'Easy':      return const Color(0xFF2DC653);
      case 'Moderate':  return const Color(0xFFE9A21B);
      case 'Hard':      return const Color(0xFFFF6B35);
      case 'Very Hard':
      case 'Expert':    return const Color(0xFFE83A5A);
      default:          return appGrey;
    }
  }
}

// Semi-transparent frosted pill for overlaid badges
class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.52),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      ]),
    );
  }
}
