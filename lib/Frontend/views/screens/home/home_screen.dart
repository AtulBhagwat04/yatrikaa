import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_state.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:bhatkanti_app/Frontend/views/screens/explore/explore_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/community/community_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/packages_discovery_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/profile_screen.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/app_bottom_nav.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/event_horizontal_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/place_nearby_card.dart';
import 'package:bhatkanti_app/Frontend/core/models/event_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';

// Modern Widgets
import 'package:bhatkanti_app/Frontend/views/widgets/modern/modern_home_header.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/modern/modern_section_title.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/modern/modern_place_card.dart';

// ─── HomeScreen — StatefulWidget shell with local tab index ─────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final HomeBloc _homeBloc;
  DateTime? _lastBackPressTime;
  bool _showOnlineBanner = false;
  Timer? _onlineBannerTimer;

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;

    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc()..add(HomeStarted());

    // Force Edge-to-Edge mode for status bar control
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Initial reset
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _homeBloc.close();
    _onlineBannerTimer?.cancel();
    super.dispose();
  }

  void _onTabTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: BlocListener<HomeBloc, HomeState>(
        listenWhen: (p, c) => p.isOffline != c.isOffline,
        listener: (context, state) {
          // Force apply status bar color change (PhonePe style)
          SystemChrome.setSystemUIOverlayStyle(
            state.isOffline
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: const Color(0xFFE11B22),
                    statusBarIconBrightness: Brightness.light,
                  )
                : _showOnlineBanner
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: const Color(0xFF2E7D32),
                    statusBarIconBrightness: Brightness.light,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                  ),
          );

          // Handle transition to Online
          if (!state.isOffline) {
            _onlineBannerTimer?.cancel();
            setState(() => _showOnlineBanner = true);
            _onlineBannerTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _showOnlineBanner = false);
            });
          } else {
            // If we go offline, hide the online banner immediately
            setState(() => _showOnlineBanner = false);
          }
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: state.isOffline
                  ? SystemUiOverlayStyle.light.copyWith(
                      statusBarColor: const Color(0xFFE11B22),
                      statusBarIconBrightness: Brightness.light,
                    )
                  : _showOnlineBanner
                  ? SystemUiOverlayStyle.light.copyWith(
                      statusBarColor: const Color(0xFF2E7D32),
                      statusBarIconBrightness: Brightness.light,
                    )
                  : SystemUiOverlayStyle.dark.copyWith(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.dark,
                    ),
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
                child: Scaffold(
                  extendBodyBehindAppBar: true,
                  backgroundColor: onboardingBlueVeryLight,
                  body: Stack(
                    children: [
                      // 1. The main content of the app
                      IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _HomeTab(
                            onGoExplore: () => _onTabTap(1),
                            onGoPackages: () => _onTabTap(3),
                          ),
                          const ExploreScreen(),
                          const CommunityScreen(),
                          const PackagesDiscoveryScreen(),
                          const ProfileScreen(showBackButton: false),
                        ],
                      ),

                      // 2. PhonePe Style Red Status Bar & Offline Message
                      // 2. PhonePe Style Red Status Bar & Offline Message
                      if (state.isOffline)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                height: MediaQuery.of(context).padding.top,
                                color: const Color(0xFFE11B22),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                color: const Color(0xFFE11B22),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.wifi_off_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "No Internet Connection",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 2.5 Green Online Banner (Transient)
                      if (!state.isOffline && _showOnlineBanner)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                height: MediaQuery.of(context).padding.top,
                                color: const Color(0xFF2E7D32),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                color: const Color(0xFF2E7D32),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.wifi_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "You Are Online",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
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
                  bottomNavigationBar: AppBottomNav(
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onTabTap,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final VoidCallback onGoExplore;
  final VoidCallback onGoPackages;
  const _HomeTab({required this.onGoExplore, required this.onGoPackages});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final NotificationService _notificationService = NotificationService();
  bool _hasNewNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    context.read<TravelBloc>().add(TravelLoadCache());
    context.read<TravelBloc>().add(const TravelPackagesRequested());
  }

  Future<void> _checkNotifications() async {
    final result = await _notificationService.hasUnreadNotifications();
    if (mounted) {
      setState(() => _hasNewNotifications = result);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return AppStrings.goodMorning;
    if (h < 17) return AppStrings.goodAfternoon;
    if (h < 20) return AppStrings.goodEvening;
    return AppStrings.goodNight;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final fullName = authState is Authenticated
            ? authState.name
            : 'Traveler';
        final name = fullName.split(' ').first;

        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return Material(
              color: onboardingBlueVeryLight,
              child: Stack(
                children: [
                  SafeArea(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<HomeBloc>().add(HomeStarted());
                        await _checkNotifications();
                        await Future.delayed(const Duration(milliseconds: 800));
                      },
                      color: primaryBlue,
                      backgroundColor: appWhite,
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.ms),
                        children: [
                          AppAnimations.fadeIn(
                            child: ModernHomeHeader(
                              greeting: _greeting(),
                              userName: name,
                              location: state.currentLocation,
                              hasNewNotifications: _hasNewNotifications,
                              onNotificationTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  RouteNames.notifications,
                                );
                                _checkNotifications();
                              },
                            ),
                          ),

                          const SizedBox(height: AppSpacing.m),

                          AppAnimations.fadeIn(
                            duration: AppAnimations.normal,
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: blackOpacity,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(text: AppStrings.letExploreText),
                                  TextSpan(
                                    text: AppStrings.appName + "!",
                                    style: const TextStyle(color: primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.s),

                          AppAnimations.fadeIn(
                            duration: AppAnimations.slow,
                            child: Hero(
                              tag: 'search_bar',
                              child: Material(
                                color: Colors.transparent,
                                child: ModernSearchBar(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.search,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.s),

                          ModernSectionTitle(
                            title: "Featured Destinations",
                            onTap: () => Navigator.pushNamed(
                              context,
                              RouteNames.featuredDestinations,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.ms),
                          _buildFeaturedDestinations(context, state),

                          const SizedBox(height: AppSpacing.s),

                          ModernSectionTitle(
                            title: AppStrings.popularEvents,
                            onTap: () => Navigator.pushNamed(
                              context,
                              RouteNames.popularEvents,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.ms),
                          _buildEventsHorizontalCards(context, state),

                          const SizedBox(height: AppSpacing.s),

                          AppAnimations.fadeIn(
                            duration: AppAnimations.slow,
                            child: Column(
                              children: [
                                ModernSectionTitle(
                                  title: 'Travel Packages',
                                  onTap: widget.onGoPackages,
                                ),
                                const SizedBox(height: AppSpacing.ms),
                                _buildPackagesPreview(context),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.s),

                          ModernSectionTitle(
                            title: AppStrings.nearbyPopularPlaces,
                            onTap: widget.onGoExplore,
                          ),
                          const SizedBox(height: AppSpacing.ms),
                          _buildNearbySection(context, state),

                          const SizedBox(height: AppSpacing.s),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedDestinations(BuildContext context, HomeState state) {
    if (state.isLoadingRecommended) {
      return SizedBox(
        height: 300,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, i) => Container(
            width: 240,
            margin: const EdgeInsets.only(right: 16),
            child: const ShimmerBox(radius: 28),
          ),
        ),
      );
    }
    if (state.recommendedPlaces.isEmpty) return const SizedBox();
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.recommendedPlaces.take(15).length,
        itemBuilder: (context, i) {
          final place = state.recommendedPlaces.take(15).toList()[i];
          return ModernPlaceCard(
            place: place,
            width: 250,
            height: 250,
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.placeDetails,
              arguments: place.id,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsHorizontalCards(BuildContext context, HomeState state) {
    if (state.isLoadingEvents) {
      return SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, i) => Container(
            width: 190,
            margin: EdgeInsets.only(right: i < 2 ? AppSpacing.m : 0),
            child: const ShimmerBox(radius: 28),
          ),
        ),
      );
    }
    if (state.popularEvents.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_rounded, color: appGreyVeryLight, size: 48),
              const SizedBox(height: 12),
              AppText.caption(AppStrings.noEventsFound),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.popularEvents.take(10).length,
        itemBuilder: (context, i) {
          final events = state.popularEvents.take(10).toList();
          final event = events[i];
          return Padding(
            padding: EdgeInsets.only(
              right: i < events.length - 1 ? AppSpacing.m : 0,
            ),
            child: EventHorizontalCard(
              event: event,
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  RouteNames.eventDetails,
                  arguments: {'id': event.id, 'event': event},
                );
                if (result is EventModel && context.mounted) {
                  context.read<HomeBloc>().add(HomeEventUpdateEvent(result));
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbySection(BuildContext context, HomeState state) {
    if (!state.isLocationEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: primaryBlue,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Enable Location",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: blackOpacity,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Access nearby attractions, local events, and personalized travel recommendations by enabling your location.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: appGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Geolocator.openLocationSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Turn On Location",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isLoadingNearby) {
      return Column(
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            height: 110,
            child: const ShimmerBox(radius: 24),
          ),
        ),
      );
    }
    if (state.nearbyPlaces.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(child: AppText.caption(AppStrings.noPlacesFound)),
      );
    }
    return Column(
      children: state.nearbyPlaces
          .take(5)
          .map(
            (place) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.ms),
              child: PlaceNearbyCard(
                place: place,
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.placeDetails,
                  arguments: place.id,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPackagesPreview(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      buildWhen: (p, c) =>
          p.packagesStatus != c.packagesStatus || p.packages != c.packages,
      builder: (ctx, state) {
        if (state.packagesStatus == TravelStatus.loading ||
            state.packagesStatus == TravelStatus.initial) {
          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, i) => Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: const ShimmerBox(radius: 24),
              ),
            ),
          );
        }
        final preview = state.packages.take(4).toList();
        if (preview.isEmpty) {
          return GestureDetector(
            onTap: widget.onGoPackages,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: appWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryBlue.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.backpack_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.subHeading(
                          'Explore Curated Packages',
                          size: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        AppText.body(
                          'Browse unique trips across Maharashtra',
                          color: appGrey,
                          size: 11,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: primaryBlue,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: preview.length,
            itemBuilder: (ctx, i) {
              final pkg = preview[i];
              const double cardRadius = 12; // Standardized radius
              return Container(
                width: 300,
                margin: EdgeInsets.only(
                  right: i == preview.length - 1 ? 0 : 16,
                  bottom: 12,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteNames.packageDetails,
                    arguments: pkg.id,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cardRadius),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: pkg.mainPhotoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: pkg.mainPhotoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const ShimmerBox(),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: primaryBlue.withOpacity(0.1),
                                        child: const Icon(
                                          Icons.landscape_rounded,
                                          color: primaryBlue,
                                          size: 40,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: primaryBlue.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.landscape_rounded,
                                    color: primaryBlue,
                                    size: 40,
                                  ),
                                ),
                        ),
                        // Gradient Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.05),
                                  Colors.black.withOpacity(0.75),
                                  Colors.black,
                                ],
                                stops: const [0.5, 0.7, 0.9, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Remaining Seats Tag (Top Right)
                        if (pkg.maxGroupSize > 0)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.group_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  AppText.small(
                                    '${pkg.maxGroupSize - pkg.currentParticipants} SEATS LEFT',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    size: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Content (Bottom)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppText.heading(
                                        pkg.title,
                                        color: Colors.white,
                                        size: 19,
                                        fontWeight: FontWeight.w900,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Duration (at place of location)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.av_timer_rounded,
                                            color: Colors.white70,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 6),
                                          AppText.body(
                                            '${pkg.days}D / ${pkg.nights}N',
                                            color: Colors.white.withOpacity(
                                              0.85,
                                            ),
                                            size: 13,
                                            fontWeight: FontWeight.w700,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppText.small(
                                      'STARTING FROM',
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w800,
                                      size: 8,
                                    ),
                                    const SizedBox(height: 2),
                                    AppText.heading(
                                      '₹${pkg.price.toInt()}',
                                      color: Colors.white,
                                      size: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
