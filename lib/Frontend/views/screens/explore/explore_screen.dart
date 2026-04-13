import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/core/services/places_service.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_place_card.dart';
import 'package:yatrikaa/Frontend/views/widgets/place_nearby_card.dart';

// ── Lazy-load constants ───────────────────────────────────────────────────────
const int _kExplorePlacesPerPage = 12;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PlacesService _placesService = PlacesService();
  final ScrollController _scrollController = ScrollController();

  // ── Grid (lazy-loaded) state ──────────────────────────────────────────────
  final List<PlaceModel> _allPlaces = [];
  int _currentPage = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  // ── Search state ─────────────────────────────────────────────────────────
  List<PlaceModel> _searchResults = [];
  bool _isSearching = false;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPage(1, reset: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll listener (only active in grid / non-search mode) ──────────────
  void _onScroll() {
    if (_query.isNotEmpty) return; // don't lazy-load during search
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll - 300 && _hasMore && !_isLoadingMore) {
      _fetchPage(_currentPage + 1);
    }
  }

  Future<void> _fetchPage(int page, {bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoadingInitial = true;
        _allPlaces.clear();
        _currentPage = 1;
        _hasMore = false;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final results = await _placesService.getFamousMaharashtraPlaces(
        page: page,
        limit: _kExplorePlacesPerPage,
      );
      if (mounted) {
        setState(() {
          if (reset) _allPlaces.clear();
          _allPlaces.addAll(results);
          _currentPage = page;
          // hasMore is true if a full page was returned
          _hasMore = results.length >= _kExplorePlacesPerPage;
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Timer? _debounceTimer;

  Future<void> _performSearch(String query, {bool force = false}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _debounceTimer?.cancel();
      if (mounted) {
        setState(() {
          _query = "";
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (force) {
      _debounceTimer?.cancel();
      _executeSearch(trimmedQuery);
      return;
    }

    // DEBOUNCE: only start searching if user pauses for 600ms
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      _executeSearch(trimmedQuery);
    });
  }

  Future<void> _executeSearch(String trimmedQuery) async {
    if (!mounted) return;

    setState(() {
      _query = trimmedQuery;
      _isSearching = true;
      _searchResults = [];
    });

    try {
      // Execute main search
      List<PlaceModel> results = await _placesService.searchPlaces(
        trimmedQuery,
      );

      // SMART SEARCH for Locations (only if the first search was for a city-like query)
      if (trimmedQuery.length >= 3 && _query == trimmedQuery) {
        final isLikelyLocation = trimmedQuery.split(' ').length <= 2;
        if (isLikelyLocation) {
          final attractions = await _placesService.searchPlaces(
            "$trimmedQuery famous tourist attractions",
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_query.isEmpty) {
              await _fetchPage(1, reset: true);
            } else {
              await _performSearch(_query, force: true);
            }
          },
          color: primaryBlue,
          backgroundColor: appWhite,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Scrolling Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: AppAnimations.fadeIn(child: _buildHeader()),
              ),
              // ── Pinned Search Bar ──────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchBarSliverDelegate(
                  child: Container(
                    color: onboardingBlueVeryLight,
                    child: AppAnimations.fadeIn(
                      duration: AppAnimations.slow,
                      child: _buildSearchBar(),
                    ),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              ..._buildSliverContent(),

              const SliverPadding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.xxxl + AppSpacing.l,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSliverContent() {
    if (_query.isEmpty) {
      return _buildExploreSliverGrid();
    }

    if (_isSearching) {
      return [SliverToBoxAdapter(child: _buildLoadingList())];
    }

    if (_searchResults.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyState())];
    }

    return [_buildResultsSliverList()];
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
        suggestionsEnabled: true,
        onSuggestionSelected: (suggestion) {
          _searchController.text = suggestion;
          _performSearch(suggestion, force: true);
          _searchFocusNode.unfocus();
        },
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

  List<Widget> _buildExploreSliverGrid() {
    if (_isLoadingInitial) {
      return [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.ms),
          sliver: SliverGrid.builder(
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: const ShimmerBox(radius: 16),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.ms),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => ModernPlaceCard(
              place: _allPlaces[i],
              margin: EdgeInsets.zero,
              radius: 16, // Matched with requested range
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(
                  context,
                  RouteNames.placeDetails,
                  arguments: {
                    'placeId': _allPlaces[i].id,
                    'place': _allPlaces[i],
                  },
                );
              },
            ),
            childCount: _allPlaces.length,
          ),
        ),
      ),
      if (_isLoadingMore)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, a) => const ShimmerBox(radius: 16),
              childCount: 2,
            ),
          ),
        ),
      if (!_hasMore && _allPlaces.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: AppText.caption(
                '✓ All places loaded',
                color: appGreyLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildResultsSliverList() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.ms),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _buildPlaceItem(_searchResults[i], index: i),
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildPlaceItem(PlaceModel place, {required int index}) {
    return AppAnimations.fadeIn(
      duration: Duration(milliseconds: 400 + (index * 100)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.ms),
        child: PlaceNearbyCard(
          place: place,
          onTap: () => Navigator.pushNamed(
            context,
            RouteNames.placeDetails,
            arguments: {'placeId': place.id, 'place': place},
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.ms),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
          const SizedBox(height: 100),
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

// ── Search Bar Delegate (Pinned/Sticky) ──────────────────────────────────────
class _SearchBarSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SearchBarSliverDelegate({required this.child});

  @override
  double get minExtent => 74.0;
  @override
  double get maxExtent => 74.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SearchBarSliverDelegate oldDelegate) => true;
}
