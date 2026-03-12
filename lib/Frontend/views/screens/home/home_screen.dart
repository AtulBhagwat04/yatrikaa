import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_categories.dart';
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

  // HomeBloc lives here — survives tab switches without re-initialising
  late final HomeBloc _homeBloc;
  DateTime? _lastBackPressTime;

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
  }

  @override
  void dispose() {
    _homeBloc.close();
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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
        child: Scaffold(
          backgroundColor: onboardingBlueVeryLight,
          body: IndexedStack(
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
          bottomNavigationBar: AppBottomNav(
            selectedIndex: _selectedIndex,
            onItemSelected: _onTabTap,
          ),
        ),
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ────────────────────────────────────────────

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final VoidCallback onGoExplore;
  // Callback to jump to index 3 (Packages tab) from the home tab
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
    // Pre-load a few packages for the home preview
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
    // AuthBloc for user identity
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final fullName = authState is Authenticated
            ? authState.name
            : 'Traveler';
        final name = fullName.split(' ').first;

        // HomeBloc for places / location data
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: onboardingBlueVeryLight,
              body: SafeArea(
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
                      // ── Modern Header ──────────────────────────────────────────
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

                      // ── Explore Text ──────────────────────────────────────────
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

                      // ── Modern Search Bar ────────────────────────────────────────
                      AppAnimations.fadeIn(
                        duration: AppAnimations.slow,
                        child: ModernSearchBar(
                          onTap: () => widget.onGoExplore(),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.m),

                      // ── Featured Destinations ───────────────────────────────────
                      ModernSectionTitle(
                        title: "Featured Destinations",
                        onTap: widget.onGoExplore,
                      ),
                      const SizedBox(height: AppSpacing.ms),
                      _buildFeaturedDestinations(context, state),

                      const SizedBox(height: AppSpacing.l),

                      // ── Popular Events ───────────────────────────────────
                      ModernSectionTitle(
                        title: AppStrings.popularEvents,
                        onTap: widget.onGoExplore,
                      ),
                      const SizedBox(height: AppSpacing.ms),
                      _buildEventsHorizontalCards(context, state),


                      // ── Travel Packages Preview ──────────────────────────
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

                      const SizedBox(height: AppSpacing.l),

                      // ── Nearby ───────────────────────────────────────────
                      ModernSectionTitle(
                        title: AppStrings.nearbyPopularPlaces,
                        onTap: widget.onGoExplore,
                      ),
                      const SizedBox(height: AppSpacing.ms),
                      _buildNearbySection(context, state),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Featured Destinations List ───────────────────────────────────────────
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
      height: 280, //for changing card size
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.recommendedPlaces.length,
        itemBuilder: (context, i) {
          final place = state.recommendedPlaces[i];
          return ModernPlaceCard(
            place: place,
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



  // ── Popular events horizontal list ──────────────────────────────────────────
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
        itemCount: state.popularEvents.length,
        itemBuilder: (context, i) {
          final event = state.popularEvents[i];
          return Padding(
            padding: EdgeInsets.only(
              right: i < state.popularEvents.length - 1 ? AppSpacing.m : 0,
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

  // ── Nearby section vertical list ───────────────────────────────────────────
  Widget _buildNearbySection(BuildContext context, HomeState state) {
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

  // ── Travel Packages preview (home feed) — compact rows, not image cards ──
  Widget _buildPackagesPreview(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      buildWhen: (p, c) =>
          p.packagesStatus != c.packagesStatus || p.packages != c.packages,
      builder: (ctx, state) {
        // Loading — slim shimmer strips matching row height
        if (state.packagesStatus == TravelStatus.loading ||
            state.packagesStatus == TravelStatus.initial) {
          return SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, i) => Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: const ShimmerBox(radius: 20),
              ),
            ),
          );
        }

        final preview = state.packages.take(4).toList();

        // Empty — small, quiet nudge
        if (preview.isEmpty) {
          return GestureDetector(
            onTap: widget.onGoPackages,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: appWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryBlue.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.luggage_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.subHeading(
                          'Browse travel packages',
                          size: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        AppText.body(
                          'Curated trips across Maharashtra',
                          color: appGrey,
                          size: 11,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: primaryBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }

        // Horizontal Attractive Cards
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: preview.length,
            itemBuilder: (ctx, i) {
              final pkg = preview[i];
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  right: i == preview.length - 1 ? 0 : 16,
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteNames.packageDetails,
                    arguments: pkg.id,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Background Image
                        Positioned.fill(
                          child: pkg.mainPhotoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: pkg.mainPhotoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const ShimmerBox(),
                                  errorWidget: (context, url, error) => Container(
                                    color: primaryBlue.withOpacity(0.1),
                                    child: const Icon(Icons.luggage_rounded,
                                        color: primaryBlue, size: 40),
                                  ),
                                )
                              : Container(
                                  color: primaryBlue.withOpacity(0.1),
                                  child: const Icon(Icons.luggage_rounded,
                                      color: primaryBlue, size: 40),
                                ),
                        ),
                        // Soft Overlay Gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.8),
                                ],
                                stops: const [0.4, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Tags (Category & Duration)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _packageAccent(pkg.category),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  pkg.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded,
                                        color: Colors.white, size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${pkg.days}D / ${pkg.nights}N',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bottom Content
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pkg.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.place_rounded,
                                            color: Colors.white70, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          pkg.destinationName,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'STARTING AT',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '₹${pkg.price.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Color _packageAccent(String category) {
    switch (category) {
      case 'Fort Trek':
        return const Color(0xFF6C63FF);
      case 'Adventure':
        return const Color(0xFFFF6B35);
      case 'Beach':
        return const Color(0xFF00B4D8);
      case 'Spiritual':
        return const Color(0xFFE9A21B);
      case 'Wildlife':
        return const Color(0xFF2DC653);
      case 'Road Trip':
        return const Color(0xFFFF4C6A);
      case 'Weekend Trip':
        return const Color(0xFF9B5DE5);
      case 'Cultural':
        return const Color(0xFFE91E8C);
      default:
        return primaryBlue;
    }
  }
}
