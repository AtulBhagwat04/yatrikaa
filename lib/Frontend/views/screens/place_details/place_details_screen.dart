import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_assets.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/place_nearby_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/review_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/rating_badge.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/external_action_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/guide_info_card.dart';
import 'package:bhatkanti_app/Frontend/core/widgets/custom_toast.dart';
import 'full_screen_gallery.dart';

import 'bloc/place_details_bloc.dart';
import 'bloc/place_details_event.dart';
import 'bloc/place_details_state.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_event.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final String placeId;

  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PlaceDetailsBloc()..add(PlaceDetailsStarted(placeId)),
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
  int _currentPage = 0;
  bool _showAppBarTitle = false;
  bool _isDescriptionExpanded = false;

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
          if (state.status == PlaceDetailsStatus.loading) {
            return Scaffold(
              backgroundColor: onboardingBlueVeryLight,
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
              backgroundColor: onboardingBlueVeryLight,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.redAccent,
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
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => context.read<PlaceDetailsBloc>().add(
                            PlaceDetailsStarted(widget.placeId),
                          ),
                          child: const Text(
                            AppStrings.pdRetry,
                            style: TextStyle(
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
              backgroundColor: const Color(0xFFF9F9F7), // Subtle warm tone
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
                                  top: 24,
                                  left: 20,
                                  right: 20,
                                  bottom: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: onboardingBlueVeryLight,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTitleSection(place),
                                    const SizedBox(height: 20),
                                    _buildFeaturesSection(place),
                                  ],
                                ),
                              ),

                              // Section 2: Plan Your Visit (Experience + Guide)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.l,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDescriptionSection(place),
                                    const SizedBox(height: 20),
                                    _buildInfoSection(place),
                                  ],
                                ),
                              ),

                              // Section 4: Map & Nearby
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.l,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    _buildMapSection(place),
                                    const SizedBox(height: 16),
                                    _buildNearbySection(place),
                                  ],
                                ),
                              ),

                              // Section 5: Reviews
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.l,
                                  vertical: 8,
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
                  _buildBottomAction(context, place, state.isBookmarked),
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
          color: _showAppBarTitle ? Colors.white : Colors.transparent,
          boxShadow: _showAppBarTitle
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            _circularHeaderButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => Navigator.pop(context),
              isLight: !_showAppBarTitle,
            ),
            if (_showAppBarTitle)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppAnimations.fadeIn(
                    child: AppText.subHeading(
                      place.name,
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
            _circularHeaderButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              onPressed: () {
                context.read<PlaceDetailsBloc>().add(
                  PlaceDetailsFavoriteToggled(),
                );
              },
              iconColor: isFavorite ? Colors.red : Colors.black,
              isLight: !_showAppBarTitle,
            ),
            const SizedBox(width: 12),
            _circularHeaderButton(
              icon: Icons.share_rounded,
              onPressed: () => _sharePlace(place),
              isLight: !_showAppBarTitle,
            ),
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
      icon: Icon(
        icon,
        color: isLight ? Colors.white : iconColor,
        size: 24,
        shadows: isLight
            ? [
                const BoxShadow(
                  color: Colors.black26,
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
      backgroundColor: Colors.black,
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
              itemCount: place.allPhotoUrls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenGallery(
                          imageUrls: place.allPhotoUrls,
                          initialIndex: index,
                          place: place,
                        ),
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: place.allPhotoUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerBox(),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
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
                      Colors.black.withAlpha(120),
                      Colors.transparent,
                      Colors.black.withAlpha(200),
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
              bottom: 40,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AppText.caption(
                              place.category?.toUpperCase() ?? "DESTINATION",
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppText.heading(
                            place.name,
                            color: Colors.white,
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
            // Thin Progress Indicator
            if (place.allPhotoUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: List.generate(
                    place.allPhotoUrls.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? Colors.white
                              : Colors.white.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
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
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (place.isOpen ?? false)
                    ? Colors.green.withAlpha(20)
                    : Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: AppText.caption(
                (place.isOpen ?? false) ? "Open Now" : "Closed",
                color: (place.isOpen ?? false)
                    ? Colors.green[700]
                    : Colors.red[700],
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (place.distance != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              AppText.body(
                "Distance: ",
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                size: 14,
              ),
              AppText.body(
                "${place.distance!.toStringAsFixed(2)} km",
                fontWeight: FontWeight.w900,
                color: Colors.grey[600],
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
                color: Colors.grey[800],
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
        Icons.history_toggle_off,
        AppStrings.pdBestTime,
        place.bestTimeToVisit ?? AppStrings.pdYearRound,
      ),
      (
        Icons.wallet_travel_outlined,
        AppStrings.pdEntryFee,
        place.entryFee ?? AppStrings.pdFree,
      ),
      (
        Icons.access_time_filled,
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
        Icons.family_restroom_rounded,
        AppStrings.pdSuitableFor,
        place.suitableFor ?? "Everyone",
      ),
      (
        Icons.camera_alt_rounded,
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
        AppText.subHeading(
          "Plan Your Visit",
          fontWeight: FontWeight.w900,
          size: 18,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: infoItems.length,
          itemBuilder: (context, index) {
            final item = infoItems[index];

            return GuideInfoCard(
              icon: item.$1,
              label: item.$2,
              value: item.$3.toString(),
            );
          },
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: const DecorationImage(
                        image: NetworkImage(AppAssets.dummyMapUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(20),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 4,
                            ),
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
              Padding(
                padding: const EdgeInsets.all(20),
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
                            color: Colors.grey[500],
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
                        foregroundColor: Colors.white,
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

  Widget _buildBottomAction(
    BuildContext context,
    PlaceModel place,
    bool isBookmarked,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Bookmark Button
              Container(
                decoration: BoxDecoration(
                  color: isBookmarked
                      ? primaryBlue.withAlpha(20)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBookmarked ? primaryBlue : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.read<PlaceDetailsBloc>().add(
                        PlaceDetailsBookmarkToggled(),
                      );
                      final authState = context.read<AuthBloc>().state;
                      if (authState is Authenticated) {
                        context.read<AuthBloc>().add(
                          UpdateAuthCounts(
                            savedCount: isBookmarked
                                ? authState.savedCount - 1
                                : authState.savedCount + 1,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isBookmarked ? primaryBlue : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Start Trip Button
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is Authenticated) {
                          context.read<AuthBloc>().add(
                            UpdateAuthCounts(
                              tripsCount: authState.tripsCount + 1,
                            ),
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppStrings.pdStartingTripPrefix}${place.name}${AppStrings.pdStartingTripSuffix}',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            AppText.button(
                              AppStrings.pdStartMyTrip.toUpperCase(),
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              size: 14,
                              letterSpacing: 1.2,
                            ),
                          ],
                        ),
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
