import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_state.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_place_card.dart';
import 'package:yatrikaa/Frontend/views/widgets/place_nearby_card.dart';

// ── Constants ──────────────────────────────────────────────────────────────────
const int _kPageSize = 20;
const int _kLazyBatchSize = 10;

// ─── Entry Point ──────────────────────────────────────────────────────────────
class FeaturedDestinationsScreen extends StatelessWidget {
  const FeaturedDestinationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(HomeStarted()),
      child: const _FeaturedDestinationsView(),
    );
  }
}

// ─── Main View ────────────────────────────────────────────────────────────────
class _FeaturedDestinationsView extends StatefulWidget {
  const _FeaturedDestinationsView();

  @override
  State<_FeaturedDestinationsView> createState() =>
      _FeaturedDestinationsViewState();
}

class _FeaturedDestinationsViewState extends State<_FeaturedDestinationsView> {
  // ── View state ─────────────────────────────────────────────────────────────
  bool _isGridView = true;
  String _sortBy = 'rating'; // 'rating' | 'name' | 'distance'

  // ── Lazy loading ───────────────────────────────────────────────────────────
  int _visibleCount = _kPageSize;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Lazy load trigger ──────────────────────────────────────────────────────
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    // Load more when within 200px of bottom
    if (current >= maxScroll - 200 && !_isLoadingMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    // Access bloc state directly to check total
    final state = context.read<HomeBloc>().state;
    final total = state.recommendedPlaces.length;
    if (_visibleCount >= total) return;

    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _visibleCount = (_visibleCount + _kLazyBatchSize).clamp(0, total);
          _isLoadingMore = false;
        });
      }
    });
  }

  // ── Sort helper (only on visible slice) ────────────────────────────────────
  List<PlaceModel> _sorted(List<PlaceModel> all) {
    // Take only the visible slice first, then sort just those
    final slice = all.take(_visibleCount).toList();
    switch (_sortBy) {
      case 'name':
        slice.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'distance':
        slice.sort((a, b) {
          final da = a.distance ?? double.infinity;
          final db = b.distance ?? double.infinity;
          return da.compareTo(db);
        });
        break;
      case 'rating':
      default:
        slice.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return slice;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (ctx, _) => [
              // ── Standard project AppBar ─────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: onboardingBlueVeryLight,
                elevation: 0,
                scrolledUnderElevation: 2,
                surfaceTintColor: Colors.white,
                title: AppText.heading(
                  'Featured Destinations',
                  fontWeight: FontWeight.w900,
                  size: 20,
                ),
                centerTitle: true,
              ),

              // ── Sticky top bar (Sort + View toggle) ─────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _TopBarDelegate(
                  isLoading: state.isLoadingRecommended,
                  totalVisible: state.isLoadingRecommended
                      ? 0
                      : _sorted(state.recommendedPlaces).length,
                  total: state.recommendedPlaces.length,
                  sortBy: _sortBy,
                  isGridView: _isGridView,
                  onSortChanged: (s) => setState(() => _sortBy = s),
                  onViewToggle: () =>
                      setState(() => _isGridView = !_isGridView),
                ),
              ),
            ],
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  // ── Body dispatch ──────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.isLoadingRecommended) {
      return _isGridView ? _buildGridShimmer() : _buildListShimmer();
    }
    if (state.recommendedPlaces.isEmpty) {
      return _buildEmpty();
    }

    final places = _sorted(state.recommendedPlaces);
    return _isGridView
        ? _buildGrid(context, places, state.recommendedPlaces.length)
        : _buildList(context, places, state.recommendedPlaces.length);
  }

  // ── Grid (Explore-style: ModernPlaceCard) ──────────────────────────────────
  Widget _buildGrid(
    BuildContext context,
    List<PlaceModel> places,
    int totalAvailable,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.ms,
        AppSpacing.ms,
        AppSpacing.ms,
        32,
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: places.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (ctx, i) {
        if (i >= places.length) {
          return const ShimmerBox(radius: 12);
        }
        return AppAnimations.fadeIn(
          duration: Duration(milliseconds: 300 + (i * 40)),
          child: ModernPlaceCard(
            place: places[i],
            margin: EdgeInsets.zero,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                ctx,
                RouteNames.placeDetails,
                arguments: {'placeId': places[i].id, 'place': places[i]},
              );
            },
          ),
        );
      },
    );
  }

  // ── List (Search-style: PlaceNearbyCard) ───────────────────────────────────
  Widget _buildList(
    BuildContext context,
    List<PlaceModel> places,
    int totalAvailable,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.ms,
        AppSpacing.ms,
        AppSpacing.ms,
        32,
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: places.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= places.length) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.s),
            height: 110,
            child: const ShimmerBox(radius: 12),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: AppAnimations.fadeIn(
            duration: Duration(milliseconds: 300 + (i * 40)),
            child: PlaceNearbyCard(
              place: places[i],
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pushNamed(
                  ctx,
                  RouteNames.placeDetails,
                  arguments: {'placeId': places[i].id, 'place': places[i]},
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Shimmer states ─────────────────────────────────────────────────────────
  Widget _buildGridShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.ms),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: 8,
      itemBuilder: (_, _) => const ShimmerBox(radius: 12),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.ms),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        height: 110,
        child: const ShimmerBox(radius: 12),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.explore_off_rounded,
              size: 56,
              color: appGreyLight,
            ),
          ),
          const SizedBox(height: 20),
          AppText.subHeading(
            'No Destinations Found',
            size: 18,
            fontWeight: FontWeight.w800,
            color: appGrey,
          ),
          const SizedBox(height: 8),
          AppText.body('Pull down to refresh', color: appGrey, size: 13),
        ],
      ),
    );
  }
}

// ─── Sticky Top Bar Delegate ──────────────────────────────────────────────────
class _TopBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isLoading;
  final int totalVisible;
  final int total;
  final String sortBy;
  final bool isGridView;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onViewToggle;

  const _TopBarDelegate({
    required this.isLoading,
    required this.totalVisible,
    required this.total,
    required this.sortBy,
    required this.isGridView,
    required this.onSortChanged,
    required this.onViewToggle,
  });

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 48,
      color: onboardingBlueVeryLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ms,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Sort By inline dropdown (Left, replacing count) ────────────
          _SortDropdown(sortBy: sortBy, onChanged: onSortChanged),

          // ── Grid / List toggle (Right) ─────────────────────────────────
          GestureDetector(
            onTap: onViewToggle,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: appWhite,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: appBlack,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TopBarDelegate old) =>
      old.isLoading != isLoading ||
      old.totalVisible != totalVisible ||
      old.total != total ||
      old.sortBy != sortBy ||
      old.isGridView != isGridView;
}

// ─── Inline Sort Dropdown ─────────────────────────────────────────────────────
class _SortDropdown extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onChanged;

  const _SortDropdown({required this.sortBy, required this.onChanged});

  String _label(String value) {
    switch (value) {
      case 'name':
        return 'A – Z';
      case 'distance':
        return 'Nearest';
      default:
        return 'Top Rated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sortBy,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: appBlack,
            size: 16,
          ),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: appBlack,
          ),
          dropdownColor: appWhite,
          borderRadius: BorderRadius.circular(12),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: ['rating', 'name', 'distance']
              .map(
                (v) => DropdownMenuItem<String>(
                  value: v,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        v == 'rating'
                            ? Icons.star_rounded
                            : v == 'name'
                            ? Icons.sort_by_alpha_rounded
                            : Icons.near_me_rounded,
                        size: 14,
                        color: appBlack,
                      ),
                      const SizedBox(width: 6),
                      Text(_label(v)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
