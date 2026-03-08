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
import 'package:bhatkanti_app/Frontend/views/screens/explore/explore_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/community/community_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/favorites_screen.dart';
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
      child: Scaffold(
        backgroundColor: onboardingBlueVeryLight,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeTab(onGoExplore: () => _onTabTap(1)),
            const ExploreScreen(),
            const CommunityScreen(),
            FavoritesScreen(
              showBackButton: false,
              onGoExplore: () => _onTabTap(1),
            ),
            const ProfileScreen(showBackButton: false),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _selectedIndex,
          onItemSelected: _onTabTap,
        ),
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ────────────────────────────────────────────

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback onGoExplore;
  const _HomeTab({required this.onGoExplore});

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
                    // Wait a bit for the animation to look natural
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  color: primaryBlue,
                  backgroundColor: Colors.white,
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
                          onNotificationTap: () => Navigator.pushNamed(
                            context,
                            RouteNames.notifications,
                          ),
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
                        onTap: onGoExplore,
                      ),

                      const SizedBox(height: AppSpacing.ms),
                      _buildHorizontalCards(context, state),

                      const SizedBox(height: AppSpacing.ms),

                      // ── Popular Events ───────────────────────────────────
                      SectionTitle(
                        title: AppStrings.popularEvents,
                        actionLabel: 'See all',
                        onTap: onGoExplore,
                      ),

                      const SizedBox(height: AppSpacing.ms),
                      _buildEventsHorizontalCards(context, state),

                      const SizedBox(height: AppSpacing.ms),

                      // ── Nearby ───────────────────────────────────────────
                      SectionTitle(
                        title: AppStrings.nearbyPopularPlaces,
                        actionLabel: 'See all',
                        onTap: onGoExplore,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, color: Colors.grey[300], size: 48),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_rounded, color: Colors.grey[300], size: 48),
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
          color: Colors.white,
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
}
