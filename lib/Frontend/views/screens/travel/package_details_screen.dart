import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:yatrikaa/Frontend/views/widgets/booking_form_sheet.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/rating_badge.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';

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
        if (state.detailStatus == TravelStatus.loading ||
            state.detailStatus == TravelStatus.initial) {
          return const Scaffold(
            backgroundColor: appWhite,
            body: Center(child: CircularProgressIndicator(color: primaryBlue)),
          );
        }

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

// ─────────────────────────────────────────────────────────────────────────────
// MAIN VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _PackageDetailsView extends StatefulWidget {
  final TravelPackageModel package;
  final String? heroTag;
  const _PackageDetailsView({required this.package, this.heroTag});

  @override
  State<_PackageDetailsView> createState() => _PackageDetailsViewState();
}

class _PackageDetailsViewState extends State<_PackageDetailsView> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  bool _showAppBarTitle = false;
  int _currentPage = 0;
  Timer? _timer;

  bool _inclusionsExpanded = false;
  bool _exclusionsExpanded = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 200;
      if (shouldShow != _showAppBarTitle) {
        setState(() => _showAppBarTitle = shouldShow);
      }
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      final realPage = widget.package.allPhotoUrls.length > 1
          ? page % widget.package.allPhotoUrls.length
          : 0;
      if (realPage != _currentPage) {
        setState(() => _currentPage = realPage);
      }
    });

    if (widget.package.allPhotoUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_pageController.hasClients) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appWhite,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHero(context),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(color: appWhite),
                  child: Column(
                    children: [
                      // Section 2: Experience / About
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.m,
                          AppSpacing.m,
                          AppSpacing.m,
                          AppSpacing.xs,
                        ),
                        child: _AboutSection(
                          description: widget.package.description,
                        ),
                      ),

                      // Section 3: Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.xs,
                        ),
                        child: _buildStatsCard(),
                      ),

                      if (widget.package.itinerary.isNotEmpty) ...[
                        _buildSectionDivider(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.xs,
                          ),
                          child: _buildItinerary(),
                        ),
                      ],

                      // Section 4: Inclusions
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.xs,
                        ),
                        child: _buildInclusionsExclusions(),
                      ),

                      // Section 5: Guide
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.xs,
                        ),
                        child: _buildGuideCard(),
                      ),

                      const SizedBox(height: 170),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildStickyHeader(context),
          _buildBookingBar(context),
        ],
      ),
    );
  }

  // ───────────────────────────── HERO ───────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final photos = widget.package.allPhotoUrls;
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 320,
      backgroundColor: appWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: widget.heroTag ?? 'package_${widget.package.id}',
              child: PageView.builder(
                controller: _pageController,
                itemCount: photos.length <= 1 ? photos.length : null,
                itemBuilder: (_, index) {
                  final real = photos.isNotEmpty ? index % photos.length : 0;
                  return CachedNetworkImage(
                    imageUrl: photos[real],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerBox(),
                    errorWidget: (_, __, ___) => _imageError(),
                  );
                },
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      appBlack.withAlpha(80),
                      Colors.transparent,
                      appBlack.withAlpha(180),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // 📸 PHOTO COUNTER
            if (photos.length > 1)
              Positioned(
                top: 110,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentPage + 1}/${photos.length}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: ListenableBuilder(
                listenable: _scrollController,
                builder: (_, __) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  final opacity = (1.0 - (offset / 250)).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: AppText.heading(
                                widget.package.title,
                                color: appWhite,
                                fontWeight: FontWeight.w900,
                                size: 26,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            RatingBadge(rating: widget.package.averageRating),
                          ],
                        ),
                      ],
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

  // ──────────────────────── STICKY HEADER ─────────────────────────────────

  Widget _buildStickyHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 85,
        padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
        decoration: BoxDecoration(
          color: _showAppBarTitle ? appWhite : Colors.transparent,
          boxShadow: _showAppBarTitle
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            _circularHeaderButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
              isLight: !_showAppBarTitle,
            ),
            if (_showAppBarTitle)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 16),
                  child: AppAnimations.fadeIn(
                    child: AppText.subHeading(
                      widget.package.title,
                      maxLines: 1,
                      fontWeight: FontWeight.w800,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            if (!_showAppBarTitle)
              _circularHeaderButton(
                icon: Icons.share_rounded,
                onPressed: () {},
                isLight: true,
              )
            else
              const SizedBox(width: 40), // Maintain symmetry
          ],
        ),
      ),
    );
  }

  Widget _circularHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isLight = false,
  }) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        icon,
        color: isLight ? appWhite : appBlack,
        size: 24,
        shadows: isLight
            ? [
                const BoxShadow(
                  color: shadowColor,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      onPressed: onPressed,
    );
  }

  Widget _imageError() {
    return Container(
      color: appGreyVeryLight,
      child: const Icon(Icons.image_not_supported, color: appGrey),
    );
  }

  // ──────────────────────── STATS CARD ───────────────────────────────────────

  Widget _buildStatsCard() {
    final items = [
      (
        Icons.timer_outlined,
        '${widget.package.days}D / ${widget.package.nights}N',
        'Duration',
      ),
      (Icons.group_outlined, '${widget.package.maxGroupSize}', 'Max Group'),
      (Icons.bar_chart_rounded, widget.package.difficulty, 'Level'),
      if (widget.package.bestSeason != null)
        (Icons.wb_sunny_outlined, widget.package.bestSeason!, 'Season'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appGreyLight),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, size: 20, color: primaryBlue),
                      const SizedBox(height: 8),
                      AppText.small(
                        item.$2,
                        fontWeight: FontWeight.w800,
                        color: appBlack,
                        size: 13,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      AppText.caption(
                        item.$3,
                        color: appGrey,
                        size: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          appGreyLight.withAlpha(0),
                          appGreyLight,
                          appGreyLight.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            appGreyLight.withAlpha(0),
            appGreyLight,
            appGreyLight,
            appGreyLight.withAlpha(0),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppText.subHeading(
            title,
            fontWeight: FontWeight.w800,
            size: 20,
          ),
        ),
      ],
    );
  }

  // ────────────────────────── ABOUT ─────────────────────────────────────────

  // ──────────────────────── ITINERARY ───────────────────────────────────────

  Widget _buildItinerary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Day-by-Day Journey'),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.package.itinerary.length,
          itemBuilder: (_, i) => _ItineraryTile(
            step: widget.package.itinerary[i],
            isLast: i == widget.package.itinerary.length - 1,
            startDate: widget.package.startDate,
          ),
        ),
      ],
    );
  }

  // ───────────────────── INCLUSIONS / EXCLUSIONS ────────────────────────────

  Widget _buildInclusionsExclusions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("What's Included"),
        const SizedBox(height: 16),
        _buildIncExcPanel(
          label: 'Included in Package',
          icon: Icons.check_circle_rounded,
          iconColor: primaryBlue,
          items: widget.package.inclusions,
          expanded: _inclusionsExpanded,
          onTap: () =>
              setState(() => _inclusionsExpanded = !_inclusionsExpanded),
          positive: true,
        ),
        if (widget.package.exclusions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildIncExcPanel(
            label: 'Not Included',
            icon: Icons.cancel_rounded,
            iconColor: primaryBlue,
            items: widget.package.exclusions,
            expanded: _exclusionsExpanded,
            onTap: () =>
                setState(() => _exclusionsExpanded = !_exclusionsExpanded),
            positive: false,
          ),
        ],
      ],
    );
  }

  Widget _buildIncExcPanel({
    required String label,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required bool expanded,
    required VoidCallback onTap,
    required bool positive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expanded ? primaryBlue : appGreyLight),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText.body(
                      label,
                      fontWeight: FontWeight.w700,
                      size: 15,
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: appGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !expanded
                ? const SizedBox(width: double.infinity, height: 0)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      children: items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    positive ? Icons.check : Icons.close,
                                    size: 14,
                                    color: positive
                                        ? onboardingBlueSoft
                                        : onboardingBlueSoft,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppText.body(
                                      item,
                                      size: 13,
                                      color: appGreyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── GUIDE CARD ─────────────────────────────────

  Widget _buildGuideCard() {
    final org = widget.package.organizer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Meet Your Guide'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appGreyLight),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: org.profileImage != null
                    ? NetworkImage(org.profileImage!)
                    : null,
                backgroundColor: primaryBlue.withAlpha(15),
                child: org.profileImage == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: primaryBlue,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppText.body(
                          org.name,
                          fontWeight: FontWeight.w800,
                          size: 18,
                        ),
                        if (org.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.verified_rounded,
                              color: primaryBlue,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: ratingColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        AppText.caption(
                          org.rating.toStringAsFixed(1),
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(width: 12),
                        AppText.caption(
                          '${org.tripsHosted} Trips Hosted',
                          color: appGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────── BOOKING BAR ─────────────────────────────────────

  Widget _buildBookingBar(BuildContext context) {
    final filled = widget.package.currentParticipants;
    final total = widget.package.maxGroupSize;
    final remaining = total - filled;
    final isFull = remaining <= 0;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABILITY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFull ? 'FULLY BOOKED' : '$remaining SPOTS LEFT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PER PERSON',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '₹${widget.package.price.toInt()}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isFull
                    ? null
                    : () => BookingFormSheet.show(
                        context,
                        packageId: widget.package.id,
                        packageTitle: widget.package.title,
                        pricePerPerson: widget.package.price,
                        availableSeats: remaining,
                      ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isFull ? Colors.white24 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText.button(
                          isFull ? 'BOOKING CLOSED' : 'PROCEED TO BOOKING',
                          color: isFull ? Colors.white38 : primaryBlue,
                          size: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        if (!isFull)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: primaryBlue,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _AboutSection extends StatefulWidget {
  final String description;
  const _AboutSection({required this.description});

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, primaryBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Package Details',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: appBlack,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          child: Text(
            widget.description,
            maxLines: _expanded ? null : 4,
            textAlign: TextAlign.justify,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(
                0xFF334155,
              ), // Slate 700 for better readability
              fontSize: 16,
              height: 1.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Show Less' : 'Read More',
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: primaryBlue,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITINERARY TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ItineraryTile extends StatefulWidget {
  final ItineraryStep step;
  final bool isLast;
  final DateTime? startDate;

  const _ItineraryTile({
    required this.step,
    required this.isLast,
    this.startDate,
  });

  @override
  State<_ItineraryTile> createState() => _ItineraryTileState();
}

class _ItineraryTileState extends State<_ItineraryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final date = (widget.startDate ?? DateTime.now()).add(
      Duration(days: widget.step.day - 1),
    );

    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 36),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🚢 STRUCTURAL TIMELINE BRIDGE
          // 🚢 STRUCTURAL TIMELINE BRIDGE
          if (!widget.isLast)
            Positioned(
              top: 32, // Start from the center of the circle
              bottom: -40, // Extend to the next circle
              left: 17,
              child: Container(
                width: 2.5,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

          // 📄 ELITE NARRATIVE CARD
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _expanded ? primaryBlue.withAlpha(8) : appWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _expanded
                        ? primaryBlue.withOpacity(0.3)
                        : appGreyLight.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _expanded
                          ? primaryBlue.withOpacity(0.08)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.step.title,
                                style: GoogleFonts.outfit(
                                  color: appBlack,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                  letterSpacing: -0.3,
                                  height: 1.25,
                                ),
                              ),
                              if (!_expanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${widget.step.activities.length} Activities planned',
                                    style: GoogleFonts.outfit(
                                      color: appGrey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('d MMM').format(date).toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: primaryBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.fastOutSlowIn,
                      child: !_expanded
                          ? const SizedBox(width: double.infinity, height: 0)
                          : Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Column(
                                children: [
                                  Container(
                                    height: 1.5,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ...widget.step.activities.map(
                                    (activity) => _buildActivityItem(activity),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 📍 CHRONICLE MARKER (DAY COUNT)
          Positioned(
            top: 14, // Matches the center of the title line in the card
            left: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _expanded ? primaryBlue : appWhite,
                shape: BoxShape.circle,
                border: Border.all(color: primaryBlue, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.step.day.toString(),
                  style: GoogleFonts.outfit(
                    color: _expanded ? appWhite : primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: const Color(0xFF475569),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
