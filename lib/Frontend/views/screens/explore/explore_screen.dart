import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/utils/app_animations.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/core/services/places_service.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/modern/modern_place_card.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/place_nearby_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PlacesService _placesService = PlacesService();

  List<PlaceModel> _allPlaces = [];
  List<PlaceModel> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _query = "";
  String _lastPerformedQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchPlaces() async {
    setState(() => _isLoading = true);
    try {
      final results = await _placesService.getFamousMaharashtraPlaces();
      if (mounted) {
        setState(() {
          _allPlaces = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query, {bool force = false}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _query = "";
          _lastPerformedQuery = "";
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (trimmedQuery == _lastPerformedQuery && !force) return;

    if (mounted) {
      setState(() {
        _query = trimmedQuery;
        _lastPerformedQuery = trimmedQuery;
        _isSearching = true;
        _searchResults = [];
      });
    }

    try {
      // Primary Search
      List<PlaceModel> results = await _placesService.searchPlaces(
        trimmedQuery,
        null,
        null,
      );

      // SMART SEARCH for Locations
      if (trimmedQuery.length >= 3) {
        final isLikelyLocation = trimmedQuery.split(' ').length <= 2;
        if (isLikelyLocation) {
          final attractions = await _placesService.searchPlaces(
            "$trimmedQuery famous tourist attractions",
            null,
            null,
          );

          final existingIds = results.map((p) => p.id).toSet();
          for (var place in attractions) {
            if (!existingIds.contains(place.id)) {
              results.add(place);
              existingIds.add(place.id);
            }
          }
          results.sort(
            (a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal),
          );
        }
      }

      if (mounted && _query == trimmedQuery) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && _query == trimmedQuery) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: Stack(
        children: [
          // ── Background Gradient ──────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryBlue.withOpacity(0.05),
                    onboardingBlueVeryLight,
                    onboardingBlueVeryLight,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAnimations.fadeIn(child: _buildHeader()),
                AppAnimations.fadeIn(
                  duration: AppAnimations.slow,
                  child: _buildSearchBar(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ms,
        vertical: AppSpacing.s,
      ),
      child: ModernSearchBar(
        controller: _searchController,
        onChanged: _performSearch,
        focusNode: _searchFocusNode,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.ms, 12, AppSpacing.ms, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading(
            'Explore',
            fontWeight: FontWeight.w900,
            size: 26,
            color: appBlack,
            letterSpacing: -0.5,
          ),
          const SizedBox(height: 2),
          AppText.caption(
            'Discover Hidden Gems',
            color: appGrey,
            fontWeight: FontWeight.w500,
            size: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_query.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchPlaces,
        color: primaryBlue,
        backgroundColor: appWhite,
        child: _buildExploreGrid(),
      );
    }

    if (_isSearching) {
      return _buildLoadingList();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildExploreGrid() {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.ms),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, i) => Container(
          decoration: BoxDecoration(
            color: appWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const ShimmerBox(radius: 24),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.ms),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _allPlaces.length,
      itemBuilder: (context, i) => ModernPlaceCard(
        place: _allPlaces[i],
        margin: EdgeInsets.zero,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            RouteNames.placeDetails,
            arguments: _allPlaces[i].id,
          );
        },
      ),
    );
  }

  Widget _buildResultsList() {
    return RefreshIndicator(
      onRefresh: () => _performSearch(_query, force: true),
      color: primaryBlue,
      backgroundColor: appWhite,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.ms),
        itemCount: _searchResults.length,
        itemBuilder: (context, i) =>
            _buildPlaceItem(_searchResults[i], index: i),
      ),
    );
  }

  Widget _buildPlaceItem(PlaceModel place, {required int index}) {
    return AppAnimations.fadeIn(
      duration: Duration(milliseconds: 400 + (index * 100)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.ms),
        child: PlaceNearbyCard(place: place),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.ms),
      itemCount: 5,
      itemBuilder: (context, i) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      height: 110,
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const ShimmerBox(radius: 16),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: appGreyVeryLight),
          const SizedBox(height: 16),
          AppText.body('No places found', color: appGrey),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _performSearch("");
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
}
