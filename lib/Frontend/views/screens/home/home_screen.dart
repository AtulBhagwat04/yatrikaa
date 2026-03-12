import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:bhatkanti_app/Frontend/views/widgets/home_header.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/location_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/place_horizontal_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/event_horizontal_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/place_nearby_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/section_title.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/category_chip.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/app_bottom_nav.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/core/models/event_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/notification_service.dart';


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
        final name = authState is Authenticated ? authState.name : 'Traveler';
        final role = authState is Authenticated ? authState.role : 'user';
        final initial = name.isNotEmpty ? name[0] : null;

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
                    // Wait a bit for the animation to look natural
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
                      // ── Header ──────────────────────────────────────────
                      AppAnimations.fadeIn(
                        child: HomeHeader(
                          greeting: _greeting(),
                          role: role,
                          userInitial: initial,
                          hasNewNotifications: _hasNewNotifications,
                          onNotificationTap: () async {
                            await Navigator.pushNamed(
                              context,
                              RouteNames.notifications,
                            );
                            _checkNotifications(); // Refresh dot when returning
                          },
                          onProfileTap: () =>
                              Navigator.pushNamed(context, RouteNames.profile),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.m),

                      // ── Location card ────────────────────────────────────
                      AppAnimations.fadeIn(
                        duration: AppAnimations.slow,
                        child: LocationCard(
                          location: state.currentLocation,
                          isLoading: state.isLoadingLocation,
                          onTap: () => context.read<HomeBloc>().add(
                                HomeLocationRefreshRequested(),
                              ),
                          onRefresh: () => context.read<HomeBloc>().add(
                                HomeLocationRefreshRequested(),
                              ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.ms),

                      // ── Categories ───────────────────────────────────────
                      _buildCategories(context, state),

                      const SizedBox(height: AppSpacing.ms),

                      // ── Popular Places ───────────────────────────────────
                      SectionTitle(
                        title: state.selectedCategory == AppStrings.catAll
                            ? AppStrings.popularPlaces
                            : '${AppStrings.famousPrefix}${state.selectedCategory}',
                        actionLabel: 'See all',
                        onTap: widget.onGoExplore,
                      ),

                      const SizedBox(height: AppSpacing.ms),
                      _buildHorizontalCards(context, state),

                      const SizedBox(height: AppSpacing.ms),

                      // ── Popular Events ───────────────────────────────────
                      SectionTitle(
                        title: AppStrings.popularEvents,
                        actionLabel: 'See all',
                        onTap: widget.onGoExplore,
                      ),

                      const SizedBox(height: AppSpacing.ms),
                      _buildEventsHorizontalCards(context, state),

                      const SizedBox(height: AppSpacing.ms),

                      // ── Travel Packages Preview ──────────────────────────
                      SectionTitle(
                        title: 'Travel Packages',
                        actionLabel: 'See all',
                        onTap: widget.onGoPackages,
                      ),
                      const SizedBox(height: AppSpacing.ms),
                      _buildPackagesPreview(context),

                      const SizedBox(height: AppSpacing.ms),

                      // ── Nearby ───────────────────────────────────────────
                      SectionTitle(
                        title: AppStrings.nearbyPopularPlaces,
                        actionLabel: 'See all',
                        onTap: widget.onGoExplore,
                      ),

                      const SizedBox(height: AppSpacing.ms),
                      _buildNearbySection(context, state),
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

  // ── Categories row ─────────────────────────────────────────────────────────
  Widget _buildCategories(BuildContext context, HomeState state) {
    final cats = AppCategories.categories;
    final icons = AppCategories.categoryIcons;

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cats.length,
        itemBuilder: (context, i) {
          final cat = cats[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CategoryChip(
              label: cat,
              icon: icons[cat] ?? Icons.explore_rounded,
              isSelected: state.selectedCategory == cat,
              onTap: () =>
                  context.read<HomeBloc>().add(HomeCategoryChanged(cat)),
            ),
          );
        },
      ),
    );
  }

  // ── Popular places horizontal list ─────────────────────────────────────────
  Widget _buildHorizontalCards(BuildContext context, HomeState state) {
    if (state.isLoadingRecommended) {
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

    if (state.recommendedPlaces.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, color: appGreyVeryLight, size: 48),
              const SizedBox(height: 12),
              AppText.caption(AppStrings.noPlacesFound),
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
        itemCount: state.recommendedPlaces.length,
        itemBuilder: (context, i) {
          final place = state.recommendedPlaces[i];
          return Padding(
            padding: EdgeInsets.only(
              right: i < state.recommendedPlaces.length - 1 ? AppSpacing.m : 0,
            ),
            child: PlaceHorizontalCard(
              place: place,
              onTap: () => Navigator.pushNamed(
                context,
                RouteNames.placeDetails,
                arguments: place.id,
              ),
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
          return Column(
            children: List.generate(
              3,
              (i) => Container(
                margin: EdgeInsets.only(bottom: i < 2 ? 8 : 0),
                height: 62,
                child: const ShimmerBox(radius: 14),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: appWhite,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: primaryBlue.withOpacity(0.18)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.luggage_rounded,
                      color: primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.subHeading('Browse travel packages',
                          size: 13, fontWeight: FontWeight.w700),
                      AppText.body('Curated trips across Maharashtra',
                          color: appGrey, size: 11),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: primaryBlue, size: 20),
              ]),
            ),
          );
        }

        // Compact list rows inside one rounded card container
        return Container(
          decoration: BoxDecoration(
            color: appWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: shadowColorLight,
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              ...preview.asMap().entries.map((entry) {
                final i = entry.key;
                final pkg = entry.value;
                final isLast = i == preview.length - 1;
                final accent = _packageAccent(pkg.category);

                return Column(children: [
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteNames.packageDetails,
                      arguments: pkg.id,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: i == 0
                          ? const Radius.circular(18)
                          : Radius.zero,
                      bottom: isLast
                          ? const Radius.circular(18)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(children: [
                        // Coloured accent bar (category indicator)
                        Container(
                          width: 5,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title + meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkg.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.place_outlined,
                                    size: 10, color: appGrey),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    pkg.destinationName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10, color: appGrey),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.schedule_outlined,
                                    size: 10, color: appGrey),
                                const SizedBox(width: 2),
                                Text('${pkg.days}D',
                                    style: const TextStyle(
                                        fontSize: 10, color: appGrey)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Price chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${pkg.price.toInt()}',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: appGreyLight, size: 16),
                      ]),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        thickness: 0.5,
                        color: appGreyLight.withOpacity(0.4),
                        indent: 31,
                        endIndent: 14),
                ]);
              }),
            ],
          ),
        );
      },
    );
  }

  Color _packageAccent(String category) {
    switch (category) {
      case 'Fort Trek':     return const Color(0xFF6C63FF);
      case 'Adventure':    return const Color(0xFFFF6B35);
      case 'Beach':        return const Color(0xFF00B4D8);
      case 'Spiritual':    return const Color(0xFFE9A21B);
      case 'Wildlife':     return const Color(0xFF2DC653);
      case 'Road Trip':    return const Color(0xFFFF4C6A);
      case 'Weekend Trip': return const Color(0xFF9B5DE5);
      case 'Cultural':     return const Color(0xFFE91E8C);
      default:             return primaryBlue;
    }
  }
}
