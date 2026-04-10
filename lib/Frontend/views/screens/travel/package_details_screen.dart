import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:yatrikaa/Frontend/views/widgets/add_review_sheet.dart';
import 'package:yatrikaa/Frontend/views/widgets/review_card.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:yatrikaa/Frontend/core/models/review_model.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';

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
    return BlocListener<TravelBloc, TravelState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == BookingActionStatus.success &&
            state.actionSuccessMessage != null) {
          CustomToast.showSuccess(context, state.actionSuccessMessage!);
          context.read<TravelBloc>().add(const TravelStatusReset());
        } else if (state.actionStatus == BookingActionStatus.failure &&
            state.actionError != null) {
          CustomToast.showError(context, state.actionError!);
          context.read<TravelBloc>().add(const TravelStatusReset());
        }
      },
      child: Scaffold(
        backgroundColor: appWhite,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(
            bottom: 140,
          ), // Position above booking bar
          child: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddReviewSheet(
                  id: widget.package.id,
                  onSubmitted: (rating, comment) {
                    context.read<TravelBloc>().add(
                      TravelReviewAdded(
                        packageId: widget.package.id,
                        rating: rating,
                        comment: comment,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              );
            },
            backgroundColor: primaryBlue,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            icon: const Icon(Icons.rate_review_rounded, color: appWhite),
            label: Text(
              'Rate & Review',
              style: GoogleFonts.outfit(
                color: appWhite,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<TravelBloc>().add(
              TravelPackageDetailRequested(widget.package.id),
            );
          },
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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

                          // Section 6: Reviews
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                              vertical: AppSpacing.m,
                            ),
                            child: _buildReviewsSection(),
                          ),

                          const SizedBox(height: 250),
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
        ),
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
                    placeholder: (_, _) => const ShimmerBox(),
                    errorWidget: (_, _, _) => _imageError(),
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
            // Photo counter removed as requested
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: ListenableBuilder(
                listenable: _scrollController,
                builder: (_, _) {
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
            isComingSoon: widget.package.isComingSoon,
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
                ? const SizedBox.shrink()
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
                backgroundImage: NetworkImage(org.profileUrl),
                backgroundColor: primaryBlue.withAlpha(15),
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

  // ──────────────────────── REVIEWS SECTION ─────────────────────────────────

  Widget _buildReviewsSection() {
    final reviews = widget.package.reviews;
    if (reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Guest Reviews'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.reviews_outlined,
                  size: 48,
                  color: primaryBlue.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                AppText.body(
                  'No reviews yet for this package.',
                  color: appGrey,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 8),
                AppText.caption(
                  'Be the first to share your experience!',
                  color: appGrey,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Guest Reviews (${reviews.length})'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ratingColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: ratingColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.package.averageRating.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: ratingColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final authState = context.read<AuthBloc>().state;
            final currentUserId = authState is Authenticated ? authState.id : null;
            
            // Sort to show current user's review first
            List<ReviewModel> displayReviews = List.from(reviews);
            if (currentUserId != null) {
              final userIndex = displayReviews.indexWhere((r) => r.userId == currentUserId);
              if (userIndex != -1) {
                final userReview = displayReviews.removeAt(userIndex);
                displayReviews.insert(0, userReview);
              }
            }

            return ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayReviews.length > 5 ? 5 : displayReviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final review = displayReviews[i];

                return ReviewCard(
                  review: review,
                  currentUserId: currentUserId,
                  onEdit: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddReviewSheet(
                        id: widget.package.id,
                        initialRating: review.rating,
                        initialComment: review.text,
                        onSubmitted: (rating, comment) {
                          context.read<TravelBloc>().add(
                                TravelReviewUpdated(
                                  packageId: widget.package.id,
                                  reviewId: review.id!,
                                  rating: rating,
                                  comment: comment,
                                ),
                              );
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Review'),
                        content: const Text('Are you sure you want to delete this review?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<TravelBloc>().add(
                                    TravelReviewDeleted(
                                      packageId: widget.package.id,
                                      reviewId: review.id!,
                                    ),
                                  );
                              Navigator.pop(ctx);
                            },
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        if (reviews.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Future: show all reviews screen
                },
                child: AppText.body(
                  "View All ${reviews.length} Reviews",
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
    final isComingSoon = widget.package.isComingSoon;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
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
                              isComingSoon
                                  ? 'STAY TUNED'
                                  : isFull
                                  ? 'FULLY BOOKED'
                                  : '$remaining SPOTS LEFT',
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
                  onTap: (isFull || isComingSoon)
                      ? null
                      : () => BookingFormSheet.show(
                          context,
                          packageId: widget.package.id,
                          packageTitle: widget.package.title,
                          guideName: widget.package.organizer.name,
                          pricePerPerson: widget.package.price,
                          availableSeats: remaining,
                        ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isFull || isComingSoon)
                          ? Colors.white24
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText.button(
                            isComingSoon
                                ? 'COMING SOON'
                                : isFull
                                ? 'BOOKING CLOSED'
                                : 'PROCEED TO BOOKING',
                            color: (isFull || isComingSoon)
                                ? Colors.white38
                                : primaryBlue,
                            size: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          if (!isFull && !isComingSoon)
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
  final bool isComingSoon;

  const _ItineraryTile({
    required this.step,
    required this.isLast,
    this.startDate,
    this.isComingSoon = false,
  });

  @override
  State<_ItineraryTile> createState() => _ItineraryTileState();
}

class _ItineraryTileState extends State<_ItineraryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 4 : 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🚢 STRUCTURAL TIMELINE BRIDGE
          if (!widget.isLast)
            Positioned(
              top: 32, // Start from the center of the circle
              bottom:
                  -20, // Extend to the next circle (adjusted for smaller margin)
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
            padding: const EdgeInsets.only(left: 45),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _expanded ? primaryBlue.withAlpha(8) : appWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _expanded
                        ? primaryBlue.withOpacity(0.5)
                        : appGreyLight.withOpacity(0.8),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.step.places.isNotEmpty)
                                        _collapsedInfoRow(
                                          Icons.location_on_rounded,
                                          widget.step.places.join(', '),
                                        ),
                                      if (widget.step.hotelName.isNotEmpty)
                                        _collapsedInfoRow(
                                          Icons.restaurant_menu,
                                          widget.step.hotelName.join(', '),
                                        ),
                                      if (widget.step.stayLocation.isNotEmpty)
                                        _collapsedInfoRow(
                                          Icons.hotel_rounded,
                                          widget.step.stayLocation.join(', '),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.step.activities.length} Activities planned',
                                        style: GoogleFonts.outfit(
                                          color: appGrey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.fastOutSlowIn,
                      child: !_expanded
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: primaryBlue.withOpacity(0.2),
                                    ),
                                  ),
                                  if (widget.step.places.isNotEmpty)
                                    _buildInfoRow(
                                      Icons.location_on_rounded,
                                      'Visit: ',
                                      widget.step.places.join(', '),
                                    ),
                                  if (widget.step.hotelName.isNotEmpty)
                                    _buildInfoRow(
                                      Icons.restaurant_menu,
                                      'Hotels/Dining: ',
                                      widget.step.hotelName.join(', '),
                                    ),
                                  if (widget.step.stayLocation.isNotEmpty)
                                    _buildInfoRow(
                                      Icons.hotel_rounded,
                                      'Stay Locations: ',
                                      widget.step.stayLocation.join(', '),
                                    ),
                                  if (widget.step.places.isNotEmpty ||
                                      widget.step.hotelName.isNotEmpty ||
                                      widget.step.stayLocation.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: primaryBlue.withOpacity(0.3),
                                      ),
                                    ),
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

  Widget _collapsedInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: primaryBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: appBlack.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: appGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: appBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
