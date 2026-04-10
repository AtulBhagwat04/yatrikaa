import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';

/// Guide / Admin dashboard showing all their own travel packages,
/// with real data fetched from the backend via TravelBloc.
class MyPackagesScreen extends StatefulWidget {
  const MyPackagesScreen({super.key});

  @override
  State<MyPackagesScreen> createState() => _MyPackagesScreenState();
}

class _MyPackagesScreenState extends State<MyPackagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _upcomingScrollController = ScrollController();
  final ScrollController _activeScrollController = ScrollController();
  final ScrollController _completedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<TravelBloc>().add(TravelMyPackagesRequested());

    _upcomingScrollController.addListener(() => _onScroll('Upcoming'));
    _activeScrollController.addListener(() => _onScroll('Active'));
    _completedScrollController.addListener(() => _onScroll('Completed'));
  }

  void _onScroll(String type) {
    final controller = type == 'Upcoming'
        ? _upcomingScrollController
        : type == 'Active'
        ? _activeScrollController
        : _completedScrollController;

    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 300) {
      final state = context.read<TravelBloc>().state;
      if (state.myPackagesStatus != TravelStatus.loading &&
          state.myPackagesHasMore) {
        context.read<TravelBloc>().add(TravelLoadMoreMyPackages());
      }
    }
  }

  @override
  void dispose() {
    _upcomingScrollController.dispose();
    _activeScrollController.dispose();
    _completedScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TravelBloc, TravelState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == BookingActionStatus.success &&
            state.actionSuccessMessage != null) {
          CustomToast.success(context, state.actionSuccessMessage!);
          // Refresh list if it was a deletion
          if (state.actionSuccessMessage!.contains('deleted')) {
            context.read<TravelBloc>().add(TravelMyPackagesRequested());
          }
          context.read<TravelBloc>().add(TravelStatusReset());
        } else if (state.actionStatus == BookingActionStatus.failure &&
            state.actionError != null) {
          CustomToast.error(context, state.actionError!);
          context.read<TravelBloc>().add(TravelStatusReset());
        }
      },
      child: BlocBuilder<TravelBloc, TravelState>(
        buildWhen: (p, c) =>
            p.myPackagesStatus != c.myPackagesStatus ||
            p.myPackages != c.myPackages,
        builder: (ctx, state) {
          final allPackages = state.myPackages;
          final hasMore = state.myPackagesHasMore;

          // Split by status for tabs
          final upcoming = allPackages
              .where((p) => p.status == 'Published' || p.status == 'Draft')
              .toList();
          final active = allPackages
              .where(
                (p) => p.currentParticipants > 0 && p.status == 'Published',
              )
              .toList();
          final completed = allPackages
              .where((p) => p.status == 'Completed')
              .toList();

          return Scaffold(
            backgroundColor: onboardingBlueVeryLight,
            body: SafeArea(
              top: false,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      backgroundColor: onboardingBlueVeryLight,
                      elevation: 0,
                      scrolledUnderElevation: 2,
                      surfaceTintColor: Colors.white,
                      title: AppText.heading(
                        'Manage Tours',
                        fontWeight: FontWeight.w900,
                        size: 22,
                      ),
                      centerTitle: true,
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: primaryBlue,
                          unselectedLabelColor: appGrey,
                          indicatorColor: primaryBlue,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          tabs: [
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Upcoming'),
                                    if (upcoming.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      _badge(upcoming.length),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const Tab(text: 'Active'),
                            const Tab(text: 'Completed'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: state.myPackagesStatus == TravelStatus.failure
                    ? _buildError(ctx)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(ctx, upcoming, 'Upcoming', hasMore),
                          _buildList(ctx, active, 'Active', hasMore),
                          _buildList(ctx, completed, 'Completed', hasMore),
                        ],
                      ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, RouteNames.createPackage).then(
                    (_) => context.read<TravelBloc>().add(
                      TravelMyPackagesRequested(),
                    ),
                  ),
              backgroundColor: primaryBlue,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tooltip: 'Create Package',
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(TravelPackageModel package) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AppText.subHeading(
          'Delete Package?',
          fontWeight: FontWeight.w800,
        ),
        content: AppText.body(
          'Are you sure you want to delete "${package.title}"? travelers who booked this trip will be notified. This action cannot be undone.',
          size: 13,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: AppText.body(
              'Cancel',
              color: appGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TravelBloc>().add(
                TravelDeletePackageRequested(package.id),
              );
            },
            child: AppText.body(
              'Delete',
              color: errorColorDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext ctx,
    List<TravelPackageModel> packages,
    String type,
    bool hasMore,
  ) {
    final ScrollController scrollController = type == 'Upcoming'
        ? _upcomingScrollController
        : type == 'Active'
        ? _activeScrollController
        : _completedScrollController;

    return RefreshIndicator(
      onRefresh: () async {
        ctx.read<TravelBloc>().add(TravelMyPackagesRequested());
        await Future.delayed(const Duration(milliseconds: 250));
      },
      color: primaryBlue,
      backgroundColor: Colors.white,
      child: packages.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: appWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: shadowColorLight,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tour_rounded,
                        size: 64,
                        color: appGreyLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppText.subHeading(
                      'No $type Packages',
                      size: 18,
                      fontWeight: FontWeight.w800,
                      color: appGrey,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: AppText.body(
                        type == 'Upcoming'
                            ? 'Set up and share your first tour package with travelers.'
                            : type == 'Active'
                            ? 'Your actively booked packages will appear here.'
                            : 'Tours you\'ve successfully hosted will show here.',
                        color: appGrey,
                        size: 13,
                        align: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (type == 'Upcoming')
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(ctx, RouteNames.createPackage),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Create Tour'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: packages.length + (hasMore ? 1 : 0),
              physics: const AlwaysScrollableScrollPhysics(),
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                if (i == packages.length) {
                  return _buildLoadingIndicator();
                }
                return _PackageCard(
                  package: packages[i],
                  heroTag: 'package_${type}_${packages[i].id}',
                  onTap: () =>
                      Navigator.pushNamed(
                        ctx,
                        RouteNames.packageDetails,
                        arguments: {
                          'id': packages[i].id,
                          'heroTag': 'package_${type}_${packages[i].id}',
                        },
                      ).then(
                        (_) => ctx.read<TravelBloc>().add(
                          TravelMyPackagesRequested(),
                        ),
                      ),
                  onEdit: () => Navigator.pushNamed(
                    ctx,
                    RouteNames.createPackage,
                    arguments: packages[i],
                  ),
                  onDelete: () => _showDeleteDialog(packages[i]),
                );
              },
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
      ),
    );
  }

  Widget _buildError(BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: errorColor),
          const SizedBox(height: 16),
          AppText.subHeading(
            'Failed to load packages',
            color: appGrey,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          AppText.body('Please check your connection', color: appGrey),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                ctx.read<TravelBloc>().add(TravelMyPackagesRequested()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: onboardingBlueVeryLight, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// ── Package Management Card ────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final TravelPackageModel package;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackageCard({
    required this.package,
    required this.heroTag,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (package.status) {
      case 'Published':
        return successColorDark;
      case 'Draft':
        return warningColorDark;
      case 'Completed':
        return appGreyDark;
      default:
        return appGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = package.maxGroupSize > 0
        ? package.currentParticipants / package.maxGroupSize
        : 0.0;
    final isFull = fill >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColorLight.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: appGreyVeryLight.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover image
                    Hero(
                      tag: heroTag,
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: package.mainPhotoUrl,
                            width: 125,
                            height: 170,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                const ShimmerBox(height: 170, width: 125),
                            errorWidget: (_, _, _) => Container(
                              width: 125,
                              height: 170,
                              decoration: BoxDecoration(
                                color: onboardingBlueVeryLight,
                              ),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: appGreyLight,
                              ),
                            ),
                          ),
                          // Rating Badge (Top Left)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    package.averageRating > 0
                                        ? package.averageRating.toStringAsFixed(
                                            1,
                                          )
                                        : 'New',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Duration Badge (Bottom Left)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${package.days}D / ${package.nights}N',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + status badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppText.body(
                                    package.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w900,
                                    size: 14,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _statusColor.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      package.status.toUpperCase(),
                                      style: TextStyle(
                                        color: _statusColor,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Destination
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: AppText.small(
                                    package.destinationName,
                                    color: appGrey,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    size: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Price Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${package.price.toInt()}',
                                  style: TextStyle(
                                    color: successColorDark,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AppText.small(
                                  '/ person',
                                  color: appGreyLight,
                                  fontWeight: FontWeight.w500,
                                  size: 9,
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Booking Progress Section
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.group_rounded,
                                      size: 14,
                                      color: isFull ? errorColor : primaryBlue,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isFull
                                          ? 'Booking Full'
                                          : '${package.currentParticipants}/${package.maxGroupSize} Spots',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isFull
                                            ? errorColor
                                            : appGreyDark,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(fill * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isFull ? errorColor : primaryBlue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Booking fill bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: fill,
                                minHeight: 5,
                                backgroundColor: appGreyVeryLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isFull
                                      ? errorColor
                                      : fill > 0.8
                                      ? warningColorDark
                                      : primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons Footer
              Container(
                decoration: BoxDecoration(
                  color: appGreyVeryLight.withOpacity(0.15),
                  border: Border(
                    top: BorderSide(
                      color: appGreyVeryLight.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        context,
                        Icons.edit_rounded,
                        'Edit',
                        primaryBlue,
                        onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        context,
                        Icons.delete_outline_rounded,
                        'Delete',
                        errorColor,
                        onDelete,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        context,
                        Icons.group_outlined,
                        'Bookings',
                        guideColor,
                        () => Navigator.pushNamed(
                          context,
                          RouteNames.bookingRequests,
                          arguments: package.id,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.15), width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: AppText.small(
                  label,
                  color: color,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
