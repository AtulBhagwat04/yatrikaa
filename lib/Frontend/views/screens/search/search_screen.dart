import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/core/services/places_service.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:yatrikaa/Frontend/views/widgets/place_nearby_card.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/core/constants/app_categories.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class SearchScreen extends StatefulWidget {
  final bool isExploreMode;
  const SearchScreen({super.key, this.isExploreMode = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PlacesService _placesService = PlacesService();

  List<PlaceModel> _searchResults = [];
  List<PlaceModel> _trendingPlaces = [];
  bool _isLoading = false;
  bool _isTrendingLoading = true;
  String _query = "";
  String _lastPerformedQuery = "";
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchTrending();

    // Request focus only if we are in explicit search mode
    if (!widget.isExploreMode) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchTrending() async {
    setState(() => _isTrendingLoading = true);
    try {
      final places = await _placesService.getFamousMaharashtraPlaces();
      if (mounted) {
        setState(() {
          _trendingPlaces = places;
          _isTrendingLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isTrendingLoading = false);
    }
  }

  Future<void> _performSearch(
    String query, {
    bool isCategory = false,
    bool force = false,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _debounceTimer?.cancel();
      if (mounted) {
        setState(() {
          _query = "";
          _lastPerformedQuery = "";
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (trimmedQuery == _lastPerformedQuery && !isCategory && !force) return;

    if (isCategory || force) {
      _debounceTimer?.cancel();
      _executeSearch(trimmedQuery, isCategory: isCategory);
      return;
    }

    // DEBOUNCE: only start searching if user pauses for 600ms
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      _executeSearch(trimmedQuery, isCategory: isCategory);
    });
  }

  Future<void> _executeSearch(String trimmedQuery, {bool isCategory = false}) async {
    if (!mounted) return;

    // Clear existing results to show loading state for new query
    setState(() {
      _query = trimmedQuery;
      _lastPerformedQuery = trimmedQuery;
      _isLoading = true;
      _searchResults = [];
    });

    try {
      List<PlaceModel> results = [];

      if (isCategory) {
        // 1. Try backend's optimized category discovery
        final keyword = _mapCategoryToKeyword(trimmedQuery);
        results = await _placesService.getFamousMaharashtraPlaces(
          category: keyword,
        );

        // 2. Fallback to broad text search if discovery returns nothing
        if (results.isEmpty) {
          results = await _placesService.searchPlaces(
            "$trimmedQuery Maharashtra",
          );
        }
      } else {
        // Standard text search for user input
        results = await _placesService.searchPlaces(trimmedQuery);

        // SMART SEARCH: If query is specific (like a city/state name),
        // fetch related attractions to show "Related Results"
        if (trimmedQuery.length >= 3 && _query == trimmedQuery) {
          final isLikelyLocation = trimmedQuery.split(' ').length <= 2;
          if (isLikelyLocation) {
            final attractions = await _placesService.searchPlaces(
              "$trimmedQuery famous tourist attractions",
            );

            // Merge and deduplicate by ID
            final existingIds = results.map((p) => p.id).toSet();
            for (var place in attractions) {
              if (!existingIds.contains(place.id)) {
                results.add(place);
                existingIds.add(place.id);
              }
            }
            // Final sort to ensure the most popular merged results are on top
            results.sort(
              (a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal),
            );
          }
        }
      }

      if (mounted && _query == trimmedQuery) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _query == trimmedQuery) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    }
  }

  String _mapCategoryToKeyword(String category) {
    // Normalize input for case-insensitive lookup
    final normalizedInput = category.trim().toLowerCase();

    final Map<String, String> mapping = {
      AppStrings.catForts.toLowerCase(): "Fort",
      AppStrings.catBeaches.toLowerCase(): "Beach",
      AppStrings.catTemples.toLowerCase(): "Temple",
      AppStrings.catHillStations.toLowerCase(): "Hill Station",
      AppStrings.catCaves.toLowerCase(): "Cave",
      AppStrings.catWaterfalls.toLowerCase(): "Waterfall",
      AppStrings.catMuseums.toLowerCase(): "Museum",
      AppStrings.catWildlife.toLowerCase(): "National Park",
      AppStrings.catLakes.toLowerCase(): "Lake",
      AppStrings.catTrekking.toLowerCase(): "Trek",
      AppStrings.catUnesco.toLowerCase(): "Heritage",
      AppStrings.catSpiritual.toLowerCase(): "Temple",
    };

    return mapping[normalizedInput] ?? category;
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
              children: [
                // ── Custom Header
                _buildHeader(),

                // ── Search Bar Section (Hero) ──────────────────────────────────
                _buildAnimatedSearchBar(),

                // ── Main Content ──────────────────────────────────────────────
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

  Widget _buildHeader() {
    final title = widget.isExploreMode ? "Explore" : "Search";
    final subtitle = widget.isExploreMode
        ? "Hidden Gems of Maharashtra"
        : "Find your next destination";

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.ms, 12, AppSpacing.ms, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.heading(
                title,
                size: 26,
                color: appBlack,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              if (widget.isExploreMode) ...[
                // Notification icon removed as per request
              ],
            ],
          ),
          const SizedBox(height: 2),
          AppText.caption(
            subtitle,
            color: appGrey,
            fontWeight: FontWeight.w500,
            size: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearchBar() {
    final searchBar = Material(
      color: Colors.transparent,
      child: ModernSearchBar(
        controller: _searchController,
        onChanged: (query) => _performSearch(query),
        focusNode: _searchFocusNode,
        autoFocus: false,
        suggestionsEnabled: true,
        onSuggestionSelected: (suggestion) {
          _searchController.text = suggestion;
          _performSearch(suggestion, force: true);
          _searchFocusNode.unfocus();
        },
      ),
    );

    if (widget.isExploreMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.ms,
          vertical: AppSpacing.ms,
        ),
        child: searchBar,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ms,
        vertical: AppSpacing.ms,
      ),
      child: Hero(tag: 'search_bar', child: searchBar),
    );
  }

  Widget _buildContent() {
    if (_query.isEmpty) {
      return widget.isExploreMode
          ? _buildExploreGridContent()
          : _buildTrendingAndCategories();
    }

    if (_isLoading) {
      return _buildLoadingList();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildExploreGridContent() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTrending,
            color: primaryBlue,
            backgroundColor: appWhite,
            child: GridView.builder(
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
              itemCount: _trendingPlaces.length,
              itemBuilder: (context, i) =>
                  _buildExploreGridItem(_trendingPlaces[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreGridItem(PlaceModel place) {
    return AppAnimations.fadeIn(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            RouteNames.placeDetails,
            arguments: {'placeId': place.id, 'place': place},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: place.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerBox(),
                  errorWidget: (context, url, error) => Container(
                    color: appGreyVeryLight,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: appGrey,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        appBlack.withOpacity(0.0),
                        appBlack.withOpacity(0.8),
                      ],
                      stops: const [0.5, 0.7, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appBlack.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: ratingColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            AppText.small(
                              place.rating.toString(),
                              color: appWhite,
                              fontWeight: FontWeight.w800,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w800,
                        color: appWhite,
                        size: 15,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: primaryBlue,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AppText.caption(
                              place.city ?? place.category ?? 'Maharashtra',
                              color: appWhite.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              size: 11,
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
      ),
    );
  }

  Widget _buildTrendingAndCategories() {
    return RefreshIndicator(
      onRefresh: _fetchTrending,
      color: primaryBlue,
      backgroundColor: appWhite,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
        children: [
          const SizedBox(height: 8),
          _buildSectionTitle("Popular Categories", null),
          const SizedBox(height: 16),
          _buildCategoryGrid(),

          const SizedBox(height: 32),
          _buildSectionTitle("Trending Now", null, color: Colors.orange),
          const SizedBox(height: 16),
          if (_isTrendingLoading)
            ...List.generate(3, (i) => _buildShimmerCard())
          else
            ..._trendingPlaces.map((place) => _buildPlaceItem(place)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData? icon, {
    Color color = primaryBlue,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
        ],
        AppText.subHeading(title, fontWeight: FontWeight.w800, size: 18),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories =
        AppCategories.categories.where((c) => c != AppStrings.catAll).toList()
          ..shuffle();

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final label = categories[i];
          final icon =
              AppCategories.categoryIcons[label] ?? Icons.explore_rounded;
          final color = AppCategories.categoryColors[label] ?? primaryBlue;

          return AppAnimations.fadeIn(
            duration: Duration(milliseconds: 300 + (i * 50)),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // Prevent unwanted focus/keyboard pop
                _searchFocusNode.unfocus();

                // Direct search with category optimization
                _performSearch(label, isCategory: true);

                // Only update text after starting search to keep query state consistent
                _searchController.text = label;
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 95,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: color.withOpacity(0.15), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: AppText.body(
                        label,
                        fontWeight: FontWeight.w700,
                        size: 10,
                        color: appBlack.withOpacity(0.8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        align: TextAlign.center,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const ShimmerBox(radius: 24),
    );
  }

  Widget _buildPlaceItem(PlaceModel place, {int index = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AppAnimations.fadeIn(
        duration: Duration(milliseconds: 500 + (index * 50)),
        child: PlaceNearbyCard(
          place: place,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(
              context,
              RouteNames.placeDetails,
              arguments: {'placeId': place.id, 'place': place},
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60,
              color: primaryBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          AppText.heading(
            "No Results Found",
            size: 20,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText.body(
              "${AppStrings.noMatchesFound} \"$_query\". Try searching for forts, beaches or popular cities.",
              color: appGrey,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
