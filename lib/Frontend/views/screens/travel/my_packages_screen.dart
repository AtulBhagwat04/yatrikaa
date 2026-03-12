import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/models/travel_package_model.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_state.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<TravelBloc>().add(TravelMyPackagesRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      buildWhen: (p, c) =>
          p.myPackagesStatus != c.myPackagesStatus ||
          p.myPackages != c.myPackages,
      builder: (ctx, state) {
        // Split by status for tabs
        final upcoming = state.myPackages
            .where((p) => p.status == 'Published' || p.status == 'Draft')
            .toList();
        final active = state.myPackages
            .where((p) => p.currentParticipants > 0 && p.status == 'Published')
            .toList();
        final completed = state.myPackages
            .where((p) => p.status == 'Completed')
            .toList();

        return Scaffold(
          backgroundColor: onboardingBlueVeryLight,
          appBar: AppBar(
            backgroundColor: onboardingBlueVeryLight,
            elevation: 0,
            title: AppText.subHeading('My Packages',
                fontWeight: FontWeight.w800, size: 20),
            centerTitle: true,
            actions: [
              if (state.myPackagesStatus == TravelStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryBlue),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
                  onPressed: () =>
                      ctx.read<TravelBloc>().add(TravelMyPackagesRequested()),
                ),
              IconButton(
                onPressed: () => Navigator.pushNamed(
                        ctx, RouteNames.createPackage)
                    .then((_) => ctx
                        .read<TravelBloc>()
                        .add(TravelMyPackagesRequested())),
                icon: const Icon(Icons.add_circle_rounded,
                    color: primaryBlue, size: 28),
                tooltip: 'Create Package',
              ),
              const SizedBox(width: 4),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: primaryBlue,
              unselectedLabelColor: appGrey,
              indicatorColor: primaryBlue,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Upcoming'),
                    if (upcoming.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _badge(upcoming.length),
                    ],
                  ]),
                ),
                const Tab(text: 'Active'),
                const Tab(text: 'Completed'),
              ],
            ),
          ),
          body: state.myPackagesStatus == TravelStatus.failure
              ? _buildError(ctx)
              : RefreshIndicator(
                  onRefresh: () async => ctx
                      .read<TravelBloc>()
                      .add(TravelMyPackagesRequested()),
                  color: primaryBlue,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(ctx, upcoming, 'upcoming'),
                      _buildList(ctx, active, 'active'),
                      _buildList(ctx, completed, 'completed'),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _badge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: primaryBlue, borderRadius: BorderRadius.circular(10)),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildList(
      BuildContext ctx, List<TravelPackageModel> packages, String type) {
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tour_rounded, size: 64, color: appGreyLight),
            const SizedBox(height: 16),
            AppText.subHeading('No ${_capitalize(type)} Packages',
                size: 18,
                fontWeight: FontWeight.w700,
                color: appGrey),
            const SizedBox(height: 8),
            AppText.body(
              type == 'upcoming'
                  ? 'Create your first travel package!'
                  : type == 'active'
                      ? 'Packages with bookings will appear here.'
                      : 'Packages you\'ve hosted will show here.',
              color: appGrey,
              size: 13,
              align: TextAlign.center,
            ),
            if (type == 'upcoming') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(ctx, RouteNames.createPackage),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Package'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.ms),
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PackageCard(
        package: packages[i],
        onTap: () => Navigator.pushNamed(
          ctx,
          RouteNames.packageDetails,
          arguments: packages[i].id,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: appGreyLight),
          const SizedBox(height: 16),
          AppText.subHeading('Could not load packages',
              color: appGrey, fontWeight: FontWeight.w600),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ctx.read<TravelBloc>().add(TravelMyPackagesRequested()),
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Package Management Card ────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final TravelPackageModel package;
  final VoidCallback onTap;

  const _PackageCard({required this.package, required this.onTap});

  Color get _statusColor {
    switch (package.status) {
      case 'Published':  return successColorDark;
      case 'Draft':      return warningColorDark;
      case 'Completed':  return appGreyDark;
      default:           return appGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = package.maxGroupSize > 0
        ? package.currentParticipants / package.maxGroupSize
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: shadowColorLight,
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: package.mainPhotoUrl,
                width: 100,
                height: 130,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(width: 100, color: onboardingBlueLight),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(package.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(package.status,
                              style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Destination
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: appGrey),
                      const SizedBox(width: 3),
                      Text(package.destinationName,
                          style: const TextStyle(
                              color: appGrey, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ]),
                    const SizedBox(height: 4),

                    // Stats row
                    Row(children: [
                      const Icon(Icons.people_outline,
                          size: 11, color: appGrey),
                      const SizedBox(width: 3),
                      Text(
                          '${package.currentParticipants}/${package.maxGroupSize} joined',
                          style: const TextStyle(
                              fontSize: 11, color: appGrey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.monetization_on_outlined,
                          size: 11, color: primaryBlue),
                      const SizedBox(width: 3),
                      Text('₹${package.price.toInt()}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: primaryBlue,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),

                    // Booking fill bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fill,
                        minHeight: 5,
                        backgroundColor: onboardingBlueVeryLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            fill > 0.8 ? warningColorDark : primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Action buttons
                    Row(children: [
                      _actionBtn(
                        context, Icons.edit_outlined, 'Edit',
                        primaryBlue,
                        () => Navigator.pushNamed(
                          context,
                          RouteNames.packageDetails,
                          arguments: package.id,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _actionBtn(
                        context, Icons.people_outline, 'Participants',
                        guideColor, () {},
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
