import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';
import 'package:yatrikaa/Frontend/core/services/packages_service.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/category_chip.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';

// ── Lazy loading constants ───────────────────────────────────────────────────
const int _kPackagesPageSize = 12;

class PackagesDiscoveryScreen extends StatefulWidget {
  const PackagesDiscoveryScreen({super.key});

  @override
  State<PackagesDiscoveryScreen> createState() =>
      _PackagesDiscoveryScreenState();
}

class _PackagesDiscoveryScreenState extends State<PackagesDiscoveryScreen> {
  static const List<(String, IconData)> _tabs = [
    ('All', Icons.grid_view_rounded),
    ('Adventure', Icons.terrain_rounded),
    ('Fort Trek', Icons.castle_rounded),
    ('Spiritual', Icons.temple_hindu_rounded),
    ('Beach', Icons.beach_access_rounded),
    ('Road Trip', Icons.directions_car_rounded),
    ('Weekend Trip', Icons.weekend_rounded),
    ('Wildlife', Icons.forest_rounded),
    ('Cultural', Icons.museum_rounded),
  ];

  // ── Lazy-load state ─────────────────────────────────────────────────────────
  final PackagesService _service = PackagesService();
  final ScrollController _scrollController = ScrollController();
  final List<TravelPackageModel> _packages = [];
  int _currentPage = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _hasError = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPage(1, reset: true);
    // Keep bloc in sync for home screen preview
    context.read<TravelBloc>().add(const TravelPackagesRequested());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll listener ─────────────────────────────────────────────────────────
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    // Trigger when within 250px of bottom
    if (current >= maxScroll - 250 && _hasMore && !_isLoadingMore) {
      _fetchPage(_currentPage + 1);
    }
  }

  // ── Data fetcher ────────────────────────────────────────────────────────────
  Future<void> _fetchPage(int page, {bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoadingInitial = true;
        _hasError = false;
        _packages.clear();
        _currentPage = 1;
        _hasMore = false;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _service.getPackagesPaginated(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        page: page,
        limit: _kPackagesPageSize,
      );

      final newPackages = result['packages'] as List<TravelPackageModel>;
      final hasMore = result['hasMore'] as bool;

      if (mounted) {
        setState(() {
          if (reset) _packages.clear();
          _packages.addAll(newPackages);
          _currentPage = page;
          _hasMore = hasMore;
          _isLoadingInitial = false;
          _isLoadingMore = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isLoadingMore = false;
          _hasError = reset; // only show error on initial load failure
        });
      }
    }
  }

  void _onCategoryChanged(String category) {
    if (category == _selectedCategory) return;
    setState(() => _selectedCategory = category);
    // Also update bloc for the category chips UI
    context.read<TravelBloc>().add(TravelCategoryChanged(category));
    _fetchPage(1, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryBlue,
          displacement: 120,
          onRefresh: () => _fetchPage(1, reset: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Modern Header ─────────────────────────────────────────────
              _buildHeader(context),

              // ── Category chips ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: _buildTabRow(context),
                ),
              ),

              // ── Package list info ──────────────────────────────────────────
              if (!_isLoadingInitial && _packages.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.body(
                          '${_packages.length} Package${_packages.length != 1 ? 's' : ''} Loaded',
                          color: appBlack,
                          size: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        if (_selectedCategory != 'All')
                          GestureDetector(
                            onTap: () => _onCategoryChanged('All'),
                            child: AppText.caption(
                              'Clear All',
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Main Content ──────────────────────────────────────────────
              if (_isLoadingInitial)
                _buildShimmerList()
              else if (_hasError)
                SliverToBoxAdapter(child: _buildError(context))
              else if (_packages.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty(context))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        return AppAnimations.fadeIn(
                          duration: Duration(
                            milliseconds: 300 + (i.clamp(0, 10) * 60),
                          ),
                          child: _PackageCard(package: _packages[i]),
                        );
                      },
                      childCount: _packages.length,
                    ),
                  ),
                ),

              // ── "Load more" shimmer at bottom ──────────────────────────────
              if (_isLoadingMore) _buildLoadMoreShimmer(),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Modern header ───────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isOrganizer =
        authState is Authenticated &&
        (authState.role == 'Organizer' || authState.role == 'Admin');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.ms, 12, AppSpacing.ms, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.heading(
                  AppStrings.packTitle,
                  fontWeight: FontWeight.w900,
                  size: 26,
                  color: appBlack,
                  letterSpacing: -0.5,
                ),
                const SizedBox(height: 2),
                AppText.caption(
                  AppStrings.packSubtitle,
                  color: appGrey,
                  fontWeight: FontWeight.w500,
                  size: 13,
                ),
              ],
            ),
            if (isOrganizer)
              _HeaderAction(
                icon: Icons.add_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.createPackage),
                isPrimary: true,
              ),
          ],
        ),
      ),
    );
  }

  // ── Category chips ──────────────────────────────────────────────────────────
  Widget _buildTabRow(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (label, icon) = _tabs[i];
          return CategoryChip(
            label: label,
            icon: icon,
            isSelected: _selectedCategory == label,
            onTap: () => _onCategoryChanged(label),
          );
        },
      ),
    );
  }

  // ── Slivers ─────────────────────────────────────────────────────────────────
  
  Widget _buildLoadMoreShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 270,
            child: const ShimmerBox(radius: 16),
          ),
          childCount: 2,
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 270,
            child: const ShimmerBox(radius: 16),
          ),
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext ctx) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.luggage_rounded, color: primaryBlue, size: 48),
            const SizedBox(height: 20),
            AppText.heading('No Packages Found', size: 20),
            const SizedBox(height: 8),
            AppText.body('Try a different category.', color: appGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext ctx) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: appGreyLight),
            const SizedBox(height: 16),
            AppText.body('Could not load packages', color: appGrey),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchPage(1, reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TravelPackageModel package;
  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(package.difficulty);
    final seatsLeft = package.maxGroupSize - package.currentParticipants;
    final isFull = seatsLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                RouteNames.packageDetails,
                arguments: package.id,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: package.mainPhotoUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ShimmerBox(height: 180),
                      errorWidget: (_, _, _) => Container(
                        height: 180,
                        color: onboardingBlueVeryLight,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isFull
                              ? Colors.red.shade700
                              : Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFull ? 'Fully Booked' : '$seatsLeft seats left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              package.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '₹${package.price.toInt()}',
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.schedule_outlined,
                            label: '${package.days}D / ${package.nights}N',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.bar_chart_rounded,
                            label: package.difficulty,
                            color: diffColor,
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

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy': return const Color(0xFF2DC653);
      case 'Moderate': return const Color(0xFFE9A21B);
      case 'Hard': return const Color(0xFFFF6B35);
      default: return appGrey;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = appGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : primaryBlue),
      ),
    );
  }
}
