import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_categories.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';

// BLoC
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_state.dart';

// Widgets
import 'package:bhatkanti_app/Frontend/views/widgets/home_header.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/location_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/section_title.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/place_horizontal_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/place_nearby_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/category_chip.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/app_bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(HomeStarted()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    if (hour < 20) return AppStrings.goodEvening;
    return AppStrings.goodNight;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: onboardingBlueVeryLight,
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.ms),
              children: [
                AppAnimations.fadeIn(
                  child: HomeHeader(
                    greeting: _getGreeting(),
                    onNotificationTap: () {},
                    onProfileTap: () {},
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
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
                _buildCategories(context, state),
                const SizedBox(height: AppSpacing.ms),
                SectionTitle(
                  title: state.selectedCategory == AppStrings.catAll
                      ? AppStrings.popularPlaces
                      : "${AppStrings.famousPrefix}${state.selectedCategory}",
                  onRefresh: () => context.read<HomeBloc>().add(
                    HomeCategoryChanged(state.selectedCategory),
                  ),
                ),
                const SizedBox(height: AppSpacing.ms),
                _buildHorizontalCards(state),
                const SizedBox(height: AppSpacing.ms),
                SectionTitle(
                  title: AppStrings.nearbyPopularPlaces,
                  onRefresh: () => context.read<HomeBloc>().add(
                    HomeLocationRefreshRequested(),
                  ),
                ),
                const SizedBox(height: AppSpacing.ms),
                _buildNearbySection(state),
                const SizedBox(height: AppSpacing.ms),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNav(
            selectedIndex: state.selectedIndex,
            onItemSelected: (index) =>
                context.read<HomeBloc>().add(HomeTabChanged(index)),
          ),
        );
      },
    );
  }

  Widget _buildCategories(BuildContext context, HomeState state) {
    final categories = AppCategories.categories;
    final categoryIcons = AppCategories.categoryIcons;

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = state.selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CategoryChip(
              label: category,
              icon: categoryIcons[category] ?? Icons.explore_rounded,
              isSelected: isSelected,
              onTap: () =>
                  context.read<HomeBloc>().add(HomeCategoryChanged(category)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCards(HomeState state) {
    if (state.isLoadingRecommended) {
      return _buildSkeletonHorizontal();
    }

    if (state.recommendedPlaces.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: primaryWhite,
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
        itemBuilder: (context, index) {
          return PlaceHorizontalCard(
            place: state.recommendedPlaces[index],
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildNearbySection(HomeState state) {
    if (state.isLoadingNearby) {
      return _buildSkeletonNearby();
    }

    if (state.nearbyPlaces.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: primaryWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(child: AppText.caption(AppStrings.noPlacesFound)),
      );
    }

    return Column(
      children: state.nearbyPlaces
          .take(5)
          .map((place) => PlaceNearbyCard(place: place, onTap: () {}))
          .toList(),
    );
  }

  Widget _buildSkeletonHorizontal() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 190,
          margin: const EdgeInsets.only(right: AppSpacing.m),
          child: const ShimmerBox(radius: 28),
        ),
      ),
    );
  }

  Widget _buildSkeletonNearby() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          height: 110,
          child: const ShimmerBox(radius: 24),
        ),
      ),
    );
  }
}
