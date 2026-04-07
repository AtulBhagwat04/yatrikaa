import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_state.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:yatrikaa/Frontend/views/screens/explore/explore_screen.dart';
import 'package:yatrikaa/Frontend/views/screens/community/community_screen.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/packages_discovery_screen.dart';
import 'package:yatrikaa/Frontend/views/screens/profile/profile_screen.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/app_bottom_nav.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/widgets/event_horizontal_card.dart';
import 'package:yatrikaa/Frontend/views/widgets/place_nearby_card.dart';
import 'package:yatrikaa/Frontend/core/models/event_model.dart';
import 'package:yatrikaa/Frontend/views/widgets/travel/package_card.dart';
import 'package:yatrikaa/Frontend/core/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';

// Modern Widgets
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_home_header.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_section_title.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_place_card.dart';

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
    super.dispose();
  }

  void _onTabTap(int i) {
    HapticFeedback.selectionClick();
    if (_selectedIndex != i) {
      setState(() => _selectedIndex = i);
    }
  }

  Widget _getTabContent(int index) {
    switch (index) {
      case 0:
        return _HomeTab(
          key: const ValueKey('home'),
          onGoExplore: () => _onTabTap(1),
          onGoPackages: () => _onTabTap(3),
        );
      case 1:
        return const ExploreScreen(key: ValueKey('explore'));
      case 2:
        return const CommunityScreen(key: ValueKey('community'));
      case 3:
        return const PackagesDiscoveryScreen(key: ValueKey('packages'));
      case 4:
        return const ProfileScreen(
          showBackButton: false,
          key: ValueKey('profile'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;

    if (_selectedIndex != 0) {
      _onTabTap(0);
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
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: BlocListener<HomeBloc, HomeState>(
        listenWhen: (p, c) => p.isOffline != c.isOffline,
        listener: (context, state) {
          if (!state.isOffline) {
            // Re-load logic
          }
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
                child: Scaffold(
                  extendBody: true,
                  extendBodyBehindAppBar: true,
                  backgroundColor: onboardingBlueVeryLight,
                  body: Stack(
                    children: [
                      // 1. Persistent screen stack to prevent rebuilding on every tab switch
                      Stack(
                        children: List.generate(5, (index) {
                          final bool active = _selectedIndex == index;
                          return IgnorePointer(
                            ignoring: !active,
                            child: AnimatedOpacity(
                              opacity: active ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              child: AnimatedSlide(
                                offset: active
                                    ? Offset.zero
                                    : const Offset(0.02, 0), // Subtle shift
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                child: _getTabContent(index),
                              ),
                            ),
                          );
                        }),
                      ),
                      // 2. The floating navigation bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AppBottomNav(
                          selectedIndex: _selectedIndex,
                          onItemSelected: _onTabTap,
                        ),
                      ),
                    ],
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
  const _HomeTab({
    super.key,
    required this.onGoExplore,
    required this.onGoPackages,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final NotificationService _notificationService = NotificationService();
  bool _hasNewNotifications = false;

  // Scroll visibility states for alluring animations
  bool _destAtEnd = false;
  bool _eventsAtEnd = false;
  bool _packagesAtEnd = false;

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
                        await Future.delayed(const Duration(milliseconds: 250));
                      },
                      color: primaryBlue,
                      backgroundColor: appWhite,
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.ms,
                          left: AppSpacing.ms,
                          right: AppSpacing.ms,
                          bottom: 110,
                        ),
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
                                  fontSize: 24, // reduced from 28
                                  fontWeight: FontWeight.w800,
                                  color: blackOpacity,
                                  height: 1.1,
                                ),
                                children: [
                                  TextSpan(text: AppStrings.letExploreText),
                                  TextSpan(
                                    text:
                                        "${AppStrings.appName}!", // Added space
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
                            showPulse: _destAtEnd,
                            onTap: () => Navigator.pushNamed(
                              context,
                              RouteNames.featuredDestinations,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.ms),
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                final atEnd =
                                    notification.metrics.extentAfter < 50;
                                if (atEnd != _destAtEnd) {
                                  setState(() => _destAtEnd = atEnd);
                                }
                              }
                              return false;
                            },
                            child: _buildFeaturedDestinations(context, state),
                          ),

                          const SizedBox(height: AppSpacing.s),

                          ModernSectionTitle(
                            title: AppStrings.popularEvents,
                            showPulse: _eventsAtEnd,
                            onTap: () => Navigator.pushNamed(
                              context,
                              RouteNames.popularEvents,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.ms),
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                final atEnd =
                                    notification.metrics.extentAfter < 50;
                                if (atEnd != _eventsAtEnd) {
                                  setState(() => _eventsAtEnd = atEnd);
                                }
                              }
                              return false;
                            },
                            child: _buildEventsHorizontalCards(context, state),
                          ),

                          const SizedBox(height: AppSpacing.s),

                          AppAnimations.fadeIn(
                            duration: AppAnimations.slow,
                            child: Column(
                              children: [
                                ModernSectionTitle(
                                  title: 'Travel Packages',
                                  showPulse: _packagesAtEnd,
                                  onTap: widget.onGoPackages,
                                ),
                                const SizedBox(height: AppSpacing.ms),
                                NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification is ScrollUpdateNotification) {
                                      final atEnd =
                                          notification.metrics.extentAfter < 50;
                                      if (atEnd != _packagesAtEnd) {
                                        setState(() => _packagesAtEnd = atEnd);
                                      }
                                    }
                                    return false;
                                  },
                                  child: _buildPackagesPreview(context),
                                ),
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
        height: 270,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, i) => Container(
            width: 225,
            margin: const EdgeInsets.only(right: AppSpacing.m),
            child: const ShimmerBox(radius: 14),
          ),
        ),
      );
    }
    if (state.recommendedPlaces.isEmpty) return const SizedBox();
    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.recommendedPlaces.take(12).length,
        itemBuilder: (context, i) {
          final place = state.recommendedPlaces.take(12).toList()[i];
          return ModernPlaceCard(
            place: place,
            width: 225,
            height: 270,
            radius: 14,
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.placeDetails,
              arguments: {'placeId': place.id, 'place': place},
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsHorizontalCards(BuildContext context, HomeState state) {
    if (state.isLoadingEvents) {
      return SizedBox(
        height: 270,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, i) => Container(
            width: 225, // Synchronized with Destinations
            margin: EdgeInsets.only(right: i < 2 ? AppSpacing.m : 0),
            child: const ShimmerBox(radius: 14),
          ),
        ),
      );
    }
    if (state.popularEvents.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(16),
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
      height: 270, // Consistent with Destinations
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.popularEvents.take(5).length,
        itemBuilder: (context, i) {
          final events = state.popularEvents.take(5).toList();
          final event = events[i];
          return EventHorizontalCard(
            event: event,
            width: 225, // Consistent with Destinations
            radius: 14,
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
            height: 124, // Matches actual PlaceNearbyCard height
            child: const ShimmerBox(radius: 16),
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
                  arguments: {'placeId': place.id, 'place': place},
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
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, i) => Container(
                width: 290,
                margin: const EdgeInsets.only(right: AppSpacing.m),
                child: const ShimmerBox(radius: 14),
              ),
            ),
          );
        }
        final preview = state.packages.take(5).toList();
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
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: preview.length,
            itemBuilder: (ctx, i) {
              final pkg = preview[i];
              return Padding(
                padding: EdgeInsets.only(
                  right: i == preview.length - 1 ? 0 : AppSpacing.m,
                ),
                child: PackageCard(
                  package: pkg,
                  width: 290,
                  height: 210,
                  radius: 14,
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteNames.packageDetails,
                    arguments: pkg.id,
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
