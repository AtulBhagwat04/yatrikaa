import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/models/travel_package_model.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/booking_form_sheet.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;
  const PackageDetailsScreen({super.key, required this.packageId});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<TravelBloc>()
        .add(TravelPackageDetailRequested(widget.packageId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      buildWhen: (p, c) =>
          p.detailStatus != c.detailStatus || p.selectedPackage != c.selectedPackage,
      builder: (ctx, state) {
        // Loading
        if (state.detailStatus == TravelStatus.loading ||
            state.detailStatus == TravelStatus.initial) {
          return const Scaffold(
            backgroundColor: appWhite,
            body: Center(child: CircularProgressIndicator(color: primaryBlue)),
          );
        }

        // Error
        if (state.detailStatus == TravelStatus.failure ||
            state.selectedPackage == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: errorColor),
                  const SizedBox(height: 16),
                  AppText.subHeading(
                      state.detailError ?? 'Package not found',
                      color: appGrey),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ctx.read<TravelBloc>().add(
                        TravelPackageDetailRequested(widget.packageId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final pkg = state.selectedPackage!;
        return _PackageDetailsView(package: pkg);
      },
    );
  }
}

class _PackageDetailsView extends StatelessWidget {
  final TravelPackageModel package;
  const _PackageDetailsView({required this.package});

  int get _availableSeats => package.maxGroupSize - package.currentParticipants;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appWhite,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeroAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.ms),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickInfo(),
                      const SizedBox(height: 24),
                      _buildSeatsBar(),
                      const SizedBox(height: 24),
                      _buildAboutSection(),
                      const SizedBox(height: 24),
                      _buildItinerary(),
                      const SizedBox(height: 24),
                      _buildInclusionsExclusions(),
                      const SizedBox(height: 24),
                      _buildOrganizerInfo(),
                      const SizedBox(height: 100), // bottom CTA clearance
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomCTA(context),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: primaryBlue,
      leading: IconButton(
        icon: const CircleAvatar(
            backgroundColor: Colors.white,
            child:
                Icon(Icons.arrow_back_rounded, color: appBlack, size: 20)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.bookmark_border_rounded,
                  color: appBlack, size: 20)),
          onPressed: () {},
        ),
        IconButton(
          icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child:
                  Icon(Icons.share_rounded, color: appBlack, size: 20)),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: package.mainPhotoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: onboardingBlueLight),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    appBlack.withOpacity(0.1),
                    appBlack.withOpacity(0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: guideColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(package.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  AppText.heading(package.title,
                      color: Colors.white,
                      size: 26,
                      fontWeight: FontWeight.w900),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: ratingColor, size: 16),
                      const SizedBox(width: 4),
                      AppText.body(
                          '${package.averageRating.toStringAsFixed(1)} (${package.reviewCount} reviews)',
                          color: Colors.white70,
                          size: 13),
                      const Spacer(),
                      AppText.heading('₹${package.price.toInt()}',
                          color: Colors.white,
                          size: 22,
                          fontWeight: FontWeight.w800),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: onboardingBlueVeryLight,
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _info(Icons.timer_outlined, '${package.days}D/${package.nights}N', 'Duration'),
          _info(Icons.people_outline, 'Max ${package.maxGroupSize}', 'Group'),
          _info(Icons.landscape_outlined, package.difficulty, 'Difficulty'),
          if (package.bestSeason != null)
            _info(Icons.wb_sunny_outlined, package.bestSeason!, 'Season'),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: primaryBlue, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, fontSize: 12)),
        Text(label,
            style: const TextStyle(color: appGrey, fontSize: 10)),
      ],
    );
  }

  Widget _buildSeatsBar() {
    final filled = package.currentParticipants;
    final total = package.maxGroupSize;
    final fraction = total > 0 ? filled / total : 0.0;
    final remaining = total - filled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.subHeading('Availability', fontWeight: FontWeight.w700, size: 15),
            Text(
              remaining > 0 ? '$remaining seats left' : 'Fully Booked',
              style: TextStyle(
                color: remaining > 0 ? successColorDark : errorColorDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: onboardingBlueVeryLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              fraction > 0.8 ? warningColorDark : primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('$filled / $total seats filled',
            style: const TextStyle(fontSize: 11, color: appGrey)),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading('About Package', fontWeight: FontWeight.w800, size: 18),
        const SizedBox(height: 12),
        AppText.body(package.description, color: appGreyDark, size: 14, height: 1.6),
      ],
    );
  }

  Widget _buildItinerary() {
    if (package.itinerary.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading('Itinerary', fontWeight: FontWeight.w800, size: 18),
        const SizedBox(height: 16),
        ...package.itinerary.map((step) => _itineraryStep(step)),
      ],
    );
  }

  Widget _itineraryStep(ItineraryStep step) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: primaryBlue, shape: BoxShape.circle),
                child: Center(
                  child: Text('${step.day}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(child: Container(width: 2, color: onboardingBlueLight)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.subHeading(step.title, size: 15, fontWeight: FontWeight.w700),
                  const SizedBox(height: 6),
                  ...step.activities.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(child: AppText.body(a, size: 13, color: appGreyDark)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsExclusions() {
    if (package.inclusions.isEmpty && package.exclusions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (package.inclusions.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading('Included',
                    fontWeight: FontWeight.w700,
                    size: 14,
                    color: successColorDark),
                const SizedBox(height: 8),
                ...package.inclusions.map(
                    (i) => _incExcItem(i, true)),
              ],
            ),
          ),
        if (package.exclusions.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading('Not Included',
                    fontWeight: FontWeight.w700,
                    size: 14,
                    color: errorColorDark),
                const SizedBox(height: 8),
                ...package.exclusions.map(
                    (i) => _incExcItem(i, false)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _incExcItem(String text, bool included) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: included ? successColor : errorColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(child: AppText.body(text, size: 12, color: appGreyDark)),
        ],
      ),
    );
  }

  Widget _buildOrganizerInfo() {
    final org = package.organizer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: appGreyLight),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: onboardingBlueLight,
            backgroundImage: org.profileImage != null
                ? NetworkImage(org.profileImage!)
                : null,
            child: org.profileImage == null
                ? Text(org.name.isNotEmpty ? org.name[0].toUpperCase() : 'G',
                    style: const TextStyle(
                        color: primaryBlue, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading(org.name, size: 15, fontWeight: FontWeight.w800),
                AppText.body(org.role, size: 12, color: appGrey),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: ratingColor, size: 15),
                  Text(' ${org.rating.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Text('${org.tripsHosted} trips',
                  style: const TextStyle(color: appGrey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    final bool isFull = _availableSeats <= 0;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: appWhite,
          boxShadow: [
            BoxShadow(
                color: shadowColorDark.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -10))
          ],
        ),
        child: ElevatedButton(
          onPressed: isFull
              ? null
              : () => BookingFormSheet.show(
                    context,
                    packageId: package.id,
                    packageTitle: package.title,
                    pricePerPerson: package.price,
                    availableSeats: _availableSeats,
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFull ? appGreyLight : primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            isFull ? 'Fully Booked' : 'Request to Join Package',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
