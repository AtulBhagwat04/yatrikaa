import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/place_nearby_card.dart';
import 'package:yatrikaa/Frontend/views/widgets/review_card.dart';
import 'package:yatrikaa/Frontend/views/widgets/rating_badge.dart';
import 'package:yatrikaa/Frontend/views/widgets/external_action_card.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'full_screen_gallery.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'bloc/place_details_bloc.dart';
import 'bloc/place_details_event.dart';
import 'bloc/place_details_state.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_event.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final String placeId;
  final PlaceModel? initialPlace;

  const PlaceDetailsScreen({
    super.key,
    required this.placeId,
    this.initialPlace,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PlaceDetailsBloc()
            ..add(PlaceDetailsStarted(placeId, initialPlace: initialPlace)),
      child: PlaceDetailsView(placeId: placeId),
    );
  }
}

class PlaceDetailsView extends StatefulWidget {
  final String placeId;
  const PlaceDetailsView({super.key, required this.placeId});

  @override
  State<PlaceDetailsView> createState() => _PlaceDetailsViewState();
}

class _PlaceDetailsViewState extends State<PlaceDetailsView> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  bool _showAppBarTitle = false;
  bool _isDescriptionExpanded = false;
  Timer? _timer;

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

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;
      final state = context.read<PlaceDetailsBloc>().state;
      if (state.status == PlaceDetailsStatus.success && state.place != null) {
        final place = state.place!;
        if (place.allPhotoUrls.length > 1 && _pageController.hasClients) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.error}: $urlString')),
        );
      }
    }
  }

  void _sharePlace(PlaceModel place) {
    Share.share(
      '${AppStrings.pdShareMsgPrefix}${place.name}${AppStrings.pdShareMsgMid}${place.address ?? ""}',
    );
  }

  void _getDirections(PlaceModel place) {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}';
    _launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaceDetailsBloc, PlaceDetailsState>(
      listenWhen: (previous, current) =>
          previous.toastMessage != current.toastMessage,
      listener: (context, state) {
        if (state.toastMessage != null) {
          if (state.toastMessage!.contains("Error")) {
            CustomToast.error(context, state.toastMessage!);
          } else {
            CustomToast.success(context, state.toastMessage!);
          }

          // Update global character count if successful
          if (state.toastMessage!.contains("Added") ||
              state.toastMessage!.contains("Removed")) {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context.read<AuthBloc>().add(
                UpdateAuthCounts(
                  savedCount: state.isFavorite
                      ? authState.savedCount + 1
                      : authState.savedCount - 1,
                ),
              );
            }
          }
        }
      },
      child: BlocBuilder<PlaceDetailsBloc, PlaceDetailsState>(
        builder: (context, state) {
          if (state.status == PlaceDetailsStatus.loading &&
              state.place == null) {
            return Scaffold(
              backgroundColor: appWhite,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: primaryBlue,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    AppText.body(
                      "Discovering your destination...",
                      color: primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.status == PlaceDetailsStatus.failure) {
            return Scaffold(
              backgroundColor: appWhite,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: appWhite,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: errorColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppText.heading(
                        "Something went wrong",
                        size: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      const SizedBox(height: 12),
                      AppText.body(
                        state.errorMessage ?? AppStrings.error,
                        align: TextAlign.center,
                        color: appGrey,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: appWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => context.read<PlaceDetailsBloc>().add(
                            PlaceDetailsStarted(widget.placeId),
                          ),
                          child: Text(
                            AppStrings.pdRetry,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

          if (state.status == PlaceDetailsStatus.success &&
              state.place != null) {
            final place = state.place!;
            return Scaffold(
              backgroundColor: appWhite,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'This feature is coming soon! Get ready to share your experience at ${place.name}!',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: appBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                backgroundColor: primaryBlue,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                icon: const Icon(Icons.rate_review_rounded, color: appWhite),
                label: AppText.button(
                  "Rate & Review",
                  color: appWhite,
                  fontWeight: FontWeight.w800,
                  size: 14,
                  letterSpacing: 1.2,
                ),
              ),
              body: Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildHeroSection(place, state.isFavorite, context),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: primaryWhite,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(0),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Section 1: Title & Overview (White background)
                              Container(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.ml,
                                  left: AppSpacing.m,
                                  right: AppSpacing.m,
                                  bottom: AppSpacing.s,
                                ),
                                decoration: const BoxDecoration(
                                  color: appWhite,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTitleSection(place),
                                    const SizedBox(height: AppSpacing.m),
                                    _buildFeaturesSection(place),
                                  ],
                                ),
                              ),

                              _buildSectionDivider(),

                              // Section 2: Plan Your Visit (Experience + Guide)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.m,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDescriptionSection(place),
                                    const SizedBox(height: AppSpacing.m),
                                    _buildInfoSection(place),
                                  ],
                                ),
                              ),

                              _buildSectionDivider(),

                              // Section 4: Map & Nearby
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.m,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Column(
                                  children: [
                                    _buildMapSection(place),
                                    const SizedBox(height: 16),
                                    _buildNearbySection(place),
                                  ],
                                ),
                              ),

                              _buildSectionDivider(),

                              // Section 5: Reviews
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.m,
                                  vertical: AppSpacing.xs,
                                ),
                                child: _buildReviewsSection(place),
                              ),

                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildStickyHeader(context, place, state.isFavorite),
                ],
              ),
            );
          }

          return const Scaffold();
        },
      ),
    );
  }

  Widget _buildStickyHeader(
    BuildContext context,
    PlaceModel place,
    bool isFavorite,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 93,
        padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
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
                      place.name,
                      maxLines: 1,
                      align: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            if (!_showAppBarTitle) ...[
              _circularHeaderButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                onPressed: () {
                  context.read<PlaceDetailsBloc>().add(
                    PlaceDetailsFavoriteToggled(),
                  );
                },
                iconColor: isFavorite ? errorColor : appBlack,
                isLight: !_showAppBarTitle,
              ),
              const SizedBox(width: 12),
              _circularHeaderButton(
                icon: Icons.share_rounded,
                onPressed: () => _sharePlace(place),
                isLight: !_showAppBarTitle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _circularHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black,
    bool isLight = false,
  }) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        icon,
        color: isLight ? appWhite : iconColor,
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

  Widget _buildHeroSection(
    PlaceModel place,
    bool isFavorite,
    BuildContext context,
  ) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 400,
      backgroundColor: appBlack,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: place.allPhotoUrls.length <= 1
                  ? place.allPhotoUrls.length
                  : null,
              itemBuilder: (context, index) {
                final realIndex = place.allPhotoUrls.isNotEmpty
                    ? index % place.allPhotoUrls.length
                    : 0;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenGallery(
                          imageUrls: place.allPhotoUrls,
                          initialIndex: realIndex,
                          place: place,
                        ),
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: place.allPhotoUrls[realIndex],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerBox(),
                    errorWidget: (context, url, error) => Container(
                      color: appGreyVeryLight,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                );
              },
            ),
            // Improved Gradient Overlay
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
            // Dramatic Dynamic Title with Smooth Scroll Animation
            Positioned(
              left: 20,
              right: 20,
              bottom: 15,
              child: ListenableBuilder(
                listenable: _scrollController,
                builder: (context, child) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  // Syncing fade exactly with the sticky header trigger (300px)
                  final opacity = (1.0 - (offset / 300)).clamp(0.0, 1.0);
                  final slide =
                      -offset * 0.15; // More pronounced upward movement

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, slide),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.heading(
                            place.name,
                            color: appWhite,
                            fontWeight: FontWeight.w900,
                            size: 28,
                            maxLines: 2,
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

  Widget _buildTitleSection(PlaceModel place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AppText.heading(
                place.name,
                fontWeight: FontWeight.w900,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            RatingBadge(rating: place.rating),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText.body(
                      "${place.city},India",
                      color: appGrey,
                      fontWeight: FontWeight.w600,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (place.distance != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.directions, color: primaryBlue, size: 16),
              const SizedBox(width: 8),
              AppText.body(
                "Approx. ${place.distance!.toStringAsFixed(1)} km from you",
                fontWeight: FontWeight.w600,
                color: appGrey,
                size: 14,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturesSection(PlaceModel place) {
    final List<(IconData, String)> features = [];

    if (place.parkingAvailable == true) {
      features.add((Icons.local_parking_rounded, "Secure Parking"));
    }
    if (place.bestTimeToVisit != null) {
      features.add((Icons.verified_user, "Verified Spot"));
    }
    // Always add at least one generic one if list is empty
    if (features.isEmpty) {
      features.add((Icons.camera_alt_rounded, "Photo Spot"));
    }
    // Add default suitable tag
    features.add((Icons.family_restroom_rounded, "Family Friendly"));

    return Row(
      children: features.take(3).map((feature) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: onboardingBlueVeryLight.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(feature.$1, size: 18, color: primaryBlue),
                const SizedBox(height: 6),
                AppText.small(
                  feature.$2,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionSection(PlaceModel place) {
    // Generate a rich description if the API provided one is missing or too short
    String description = place.description ?? "";
    if (description.trim().isEmpty || description.length < 50) {
      description = _generateRichDescription(place);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            AppText.subHeading(
              AppStrings.pdExperience,
              fontWeight: FontWeight.w800,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: AppText.body(
                description,
                color: appGreyDark,
                align: TextAlign.justify,
                size: 14,
                height: 1.6,
                maxLines: _isDescriptionExpanded ? null : 6,
                overflow: _isDescriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              left: 0,
              top: 4,
              bottom: 4,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryBlue.withAlpha(20),
                      primaryBlue.withAlpha(100),
                      primaryBlue.withAlpha(20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        if (description.length > 200)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 12),
            child: InkWell(
              onTap: () => setState(
                () => _isDescriptionExpanded = !_isDescriptionExpanded,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.body(
                    _isDescriptionExpanded
                        ? AppStrings.pdReadLess
                        : AppStrings.pdReadFullStory,
                    color: primaryBlue,
                    fontWeight: FontWeight.w800,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isDescriptionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: primaryBlue,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _generateRichDescription(PlaceModel place) {
    final buffer = StringBuffer();
    buffer.write("${AppStrings.fbDescriptionPrefix}${place.name}. ");

    if (place.city != null) {
      buffer.write("Located in the vibrant city of ${place.city}, ");
    } else {
      buffer.write("Located amidst nature's beauty, ");
    }

    buffer.write(
      "this ${place.category?.toLowerCase() ?? 'destination'} offers a unique glimpse into local culture and heritage. ",
    );

    if (place.suitableFor != null) {
      buffer.write(
        "It is an ideal spot for ${place.suitableFor!.toLowerCase()}, making it perfect for your next trip. ",
      );
    }

    buffer.write(AppStrings.fbDescriptionSuffix);

    return buffer.toString();
  }

  Widget _buildInfoSection(PlaceModel place) {
    final infoItems = [
      (
        Icons.event_available_rounded,
        AppStrings.pdBestTime,
        place.bestTimeToVisit ?? AppStrings.pdYearRound,
      ),
      (
        Icons.payments_rounded,
        AppStrings.pdEntryFee,
        place.entryFee ?? AppStrings.pdFree,
      ),
      (
        Icons.schedule_rounded,
        AppStrings.pdTimings,
        place.timings ?? AppStrings.pdOpen247,
      ),
      (
        Icons.landscape_rounded,
        AppStrings.pdDifficulty,
        place.difficulty ?? AppStrings.pdEasy,
      ),
      (
        Icons.local_parking_rounded,
        AppStrings.pdParking,
        (place.parkingAvailable == true)
            ? AppStrings.pdAvailable
            : AppStrings.pdNotAvailable,
      ),
      (
        Icons.groups_rounded,
        AppStrings.pdSuitableFor,
        place.suitableFor ?? "Everyone",
      ),
      (
        Icons.photo_camera_rounded,
        AppStrings.pdPhotography,
        (place.photographyAllowed == false)
            ? AppStrings.pdPhotographyNotAllowed
            : AppStrings.pdPhotographyAllowed,
      ),
      (
        Icons.room_service_rounded,
        AppStrings.pdFacilities,
        (place.facilities != null && place.facilities!.isNotEmpty)
            ? place.facilities!.join(", ")
            : "Basic Facilities",
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            AppText.subHeading(
              "Know Before You Go",
              fontWeight: FontWeight.w900,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: appWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appGreyVeryLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: List.generate(infoItems.length, (index) {
              final item = infoItems[index];
              return Column(
                children: [
                  _buildExpandablePlanItem(
                    icon: item.$1,
                    label: item.$2,
                    value: item.$3.toString(),
                  ),
                  if (index != infoItems.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: appGreyVeryLight,
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
        if (place.website != null) ...[
          const SizedBox(height: 24),
          ExternalActionCard(
            icon: Icons.language_rounded,
            title: AppStrings.pdOfficialWebsite,
            subtitle: AppStrings.pdVisitWebsiteDesc,
            onTap: () => _launchUrl(place.website!),
          ),
        ],
      ],
    );
  }

  Widget _buildMapSection(PlaceModel place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading("Location", fontWeight: FontWeight.w800, size: 22),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: appWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withAlpha(30),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: ll.LatLng(place.lat, place.lng),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.yatrikaa.app',
                              ),
                            ],
                          ),
                          Container(
                            color: Colors.black.withAlpha(20),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: appWhite,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: errorColor,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (place.distance != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: appWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: shadowColor, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_walk_rounded,
                              size: 14,
                              color: primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            AppText.caption(
                              "${place.distance!.toStringAsFixed(1)} km",
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: const BoxDecoration(
                  color: appWhite,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.body(
                            place.name,
                            fontWeight: FontWeight.w800,
                            size: 16,
                          ),
                          const SizedBox(height: 4),
                          AppText.caption(
                            place.address ?? "Get directions to this location",
                            color: appGrey,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _getDirections(place),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text("Go"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: appWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildNearbySection(PlaceModel place) {
    if (place.nearbyPlaces.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(
          AppStrings.pdNearbyAttractions,
          fontWeight: FontWeight.w800,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: place.nearbyPlaces.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final nearby = place.nearbyPlaces[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16),
                child: PlaceNearbyCard(
                  place: nearby,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlaceDetailsScreen(placeId: nearby.id),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(PlaceModel place) {
    if (place.reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  context.read<AuthBloc>().add(
                    UpdateAuthCounts(reviewsCount: authState.reviewsCount + 1),
                  );
                  CustomToast.success(context, "Review added! (Simulated)");
                }
              },
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: AppText.body(
                "Add Review",
                color: primaryBlue,
                fontWeight: FontWeight.w800,
                size: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Limit to 2 review preview as requested
        ...place.reviews.take(2).map((review) => ReviewCard(review: review)),
      ],
    );
  }

  Widget _buildExpandablePlanItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: primaryBlue.withAlpha(5),
      ),
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.only(
          left: 64,
          right: 20,
          bottom: 14,
          top: 0,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        title: AppText.body(
          label,
          fontWeight: FontWeight.w700,
          size: 14,
          color: appBlack,
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: appGrey,
          size: 20,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppText.body(
              value,
              fontWeight: FontWeight.w800,
              size: 14,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.m),
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
}
