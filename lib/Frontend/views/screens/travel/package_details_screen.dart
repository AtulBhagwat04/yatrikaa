import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
// Removed unused import
import 'package:bhatkanti_app/Frontend/core/models/travel_package_model.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/booking_form_sheet.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;
  final String? heroTag;
  const PackageDetailsScreen({
    super.key,
    required this.packageId,
    this.heroTag,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TravelBloc>().add(
      TravelPackageDetailRequested(widget.packageId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      buildWhen: (p, c) =>
          p.detailStatus != c.detailStatus ||
          p.selectedPackage != c.selectedPackage,
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
                    color: appGrey,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ctx.read<TravelBloc>().add(
                      TravelPackageDetailRequested(widget.packageId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final pkg = state.selectedPackage!;
        return _PackageDetailsView(package: pkg, heroTag: widget.heroTag);
      },
    );
  }
}

class _PackageDetailsView extends StatefulWidget {
  final TravelPackageModel package;
  final String? heroTag;
  const _PackageDetailsView({required this.package, this.heroTag});

  @override
  State<_PackageDetailsView> createState() => _PackageDetailsViewState();
}

class _PackageDetailsViewState extends State<_PackageDetailsView> {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showAppBarTitle) {
        setState(() => _showAppBarTitle = true);
      } else if (_scrollController.offset <= 300 && _showAppBarTitle) {
        setState(() => _showAppBarTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _availableSeats =>
      widget.package.maxGroupSize - widget.package.currentParticipants;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHero(context),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -35),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 45),
                          _buildQuickInfo(),
                          const SizedBox(height: 32),
                          _buildAboutSection(),
                          const SizedBox(height: 32),
                          _buildVisualItinerary(),
                          const SizedBox(height: 32),
                          _buildSeatsCard(),
                          const SizedBox(height: 32),
                          _buildDetailsAccordion(),
                          const SizedBox(height: 32),
                          _buildMeetGuide(),
                          const SizedBox(height: 140), // clearance
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildStickyHeader(context),
          _buildFloatingBookingBar(context),
        ],
      ),
    );
  }

  Widget _buildModernHero(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 440,
      automaticallyImplyLeading: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image with Hero
            Hero(
              tag: widget.heroTag ?? 'package_${widget.package.id}',
              child: CachedNetworkImage(
                imageUrl: widget.package.mainPhotoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerBox(),
                errorWidget: (_, __, ___) => _buildImageError(),
              ),
            ),

            // Premium Overlay Gradients
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      appBlack.withAlpha(120),
                      Colors.transparent,
                      appBlack.withAlpha(200),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Animated Title Section (Aligned with Places/Events)
            Positioned(
              left: 20,
              right: 20,
              bottom: 60,
              child: ListenableBuilder(
                listenable: _scrollController,
                builder: (context, child) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  final opacity = (1.0 - (offset / 300)).clamp(0.0, 1.0);
                  final slide = -offset * 0.15;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, slide),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.heading(
                            widget.package.title,
                            color: appWhite,
                            fontWeight: FontWeight.w900,
                            size: 32,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: warningColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.package.destinationName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 93,
        padding: const EdgeInsets.only(top: 30, left: 10, right: 10),
        decoration: BoxDecoration(
          color: _showAppBarTitle ? appWhite : Colors.transparent,
          boxShadow: _showAppBarTitle
              ? [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            if (_showAppBarTitle)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AppAnimations.fadeIn(
                    child: AppText.subHeading(
                      widget.package.title,
                      maxLines: 1,
                      align: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            IconButton(
              icon: Icon(
                Icons.share_rounded,
                color: _showAppBarTitle ? appBlack : appWhite,
                size: 22,
              ),
              onPressed: () {
                // TODO: Implement Share
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: onboardingBlueVeryLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: appGrey,
            size: 48,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Image not available",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onboardingBlueDark.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _info(
            Icons.timer_outlined,
            '${widget.package.days}D/${widget.package.nights}N',
            'Duration',
          ),
          _info(
            Icons.people_outline,
            'Max ${widget.package.maxGroupSize}',
            'Group',
          ),
          _info(Icons.hiking_rounded, widget.package.difficulty, 'Difficulty'),
          if (widget.package.bestSeason != null)
            _info(
              Icons.wb_sunny_outlined,
              widget.package.bestSeason!,
              'Best Season',
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: appBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: appBlack,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceItem(String label, double score, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryBlue, size: 20),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 4,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(primaryBlue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: appGreyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualItinerary() {
    if (widget.package.itinerary.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Day by Day Journey",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: appBlack,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${widget.package.itinerary.length} Phases",
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.package.itinerary.length,
          itemBuilder: (context, index) {
            final step = widget.package.itinerary[index];
            final isLast = index == widget.package.itinerary.length - 1;

            return IntrinsicHeight(
              child: Row(
                children: [
                  // Timeline Column
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "${step.day}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: primaryBlue.withOpacity(0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: appBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                    Text(
                                      DateFormat('EEE, d MMM yyyy').format(
                                        (widget.package.startDate ??
                                                DateTime.now())
                                            .add(Duration(days: step.day - 1)),
                                      ),
                                      style: const TextStyle(
                                        color: primaryBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...step.activities.map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    activity,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: appGreyDark,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast) const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeatsCard() {
    final filled = widget.package.currentParticipants;
    final total = widget.package.maxGroupSize;
    final fraction = total > 0 ? filled / total : 0.0;
    final remaining = total - filled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appBlack,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: appBlack.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reservation Status",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining > 0 ? "Few Spots Ready" : "FULLY BOOKED",
                    style: GoogleFonts.outfit(
                      color: remaining > 0 ? warningColor : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "$remaining left",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 10,
                width: fraction * 300, // Approximate
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_alt_rounded,
                color: Colors.white60,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                "$filled adventurous travelers already joined",
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsAccordion() {
    return Column(
      children: [
        _accordionTile("Inclusions", widget.package.inclusions, true),
        const SizedBox(height: 12),
        _accordionTile("Exclusions", widget.package.exclusions, false),
      ],
    );
  }

  Widget _accordionTile(String title, List<String> items, bool isPositive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appGreyLight.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: appBlack,
          ),
        ),
        leading: Icon(
          isPositive ? Icons.add_task_rounded : Icons.block_flipped,
          color: isPositive ? successColor : errorColor,
          size: 24,
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: items
            .map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: isPositive
                          ? successColor.withOpacity(0.5)
                          : errorColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        i,
                        style: const TextStyle(
                          fontSize: 13,
                          color: appGreyDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMeetGuide() {
    final org = widget.package.organizer;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: org.profileImage != null
                          ? NetworkImage(org.profileImage!)
                          : null,
                      child: org.profileImage == null
                          ? Text(
                              org.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Guide",
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      org.name,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: appBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: ratingColor,
                          size: 16,
                        ),
                        Text(
                          " ${org.rating} • ${org.tripsHosted} Expeditions",
                          style: const TextStyle(
                            color: appGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Message",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "View Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Package Details",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: appBlack,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.package.description,
          style: const TextStyle(color: appGreyDark, fontSize: 15, height: 1.7),
        ),
      ],
    );
  }

  Widget _buildFloatingBookingBar(BuildContext context) {
    final bool isFull = _availableSeats <= 0;
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appBlack.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Investment",
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${widget.package.price.toInt()}",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            "/person",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isFull
                        ? null
                        : () => BookingFormSheet.show(
                            context,
                            packageId: widget.package.id,
                            packageTitle: widget.package.title,
                            pricePerPerson: widget.package.price,
                            availableSeats: _availableSeats,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull ? Colors.white24 : Colors.white,
                      foregroundColor: appBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isFull ? 'CLOSED' : 'SECURE SPOT',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
