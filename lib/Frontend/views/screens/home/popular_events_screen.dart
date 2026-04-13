import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/models/event_model.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_state.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';

// ── Constants ──────────────────────────────────────────────────────────────────
const int _kPageSize = 20;
const int _kLazyBatchSize = 10;

// ─── Entry Point ──────────────────────────────────────────────────────────────
class PopularEventsScreen extends StatelessWidget {
  const PopularEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Ensure we have loaded events
      create: (_) => HomeBloc()..add(HomeStarted()),
      child: const _PopularEventsView(),
    );
  }
}

// ─── Main View ────────────────────────────────────────────────────────────────
class _PopularEventsView extends StatefulWidget {
  const _PopularEventsView();

  @override
  State<_PopularEventsView> createState() => _PopularEventsViewState();
}

class _PopularEventsViewState extends State<_PopularEventsView> {
  // ── View state ─────────────────────────────────────────────────────────────
  bool _isGridView = true;
  String _filterStatus = 'upcoming'; // 'upcoming' | 'live' | 'completed'

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
    final state = context.read<HomeBloc>().state;
    final filteredEvents = _getFilteredList(state.popularEvents);
    final total = filteredEvents.length;

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

  // ── Filter helper ──────────────────────────────────────────────────────────
  List<EventModel> _getFilteredList(List<EventModel> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<EventModel> list = all.where((e) {
      final ed = DateTime(e.date.year, e.date.month, e.date.day);
      if (_filterStatus == 'live') {
        return ed.isAtSameMomentAs(today);
      } else if (_filterStatus == 'upcoming') {
        return ed.isAfter(today);
      } else {
        // completed
        return ed.isBefore(today);
      }
    }).toList();

    // Secondary sort: closest dates first for upcoming/live, most recent past for completed
    if (_filterStatus == 'completed') {
      list.sort((a, b) => b.date.compareTo(a.date));
    } else {
      list.sort((a, b) => a.date.compareTo(b.date));
    }

    return list;
  }

  List<EventModel> _sliced(List<EventModel> all) {
    final filtered = _getFilteredList(all);
    return filtered.take(_visibleCount).toList();
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
                  'Popular Events',
                  fontWeight: FontWeight.w900,
                  size: 20,
                ),
                centerTitle: true,
              ),

              // ── Sticky top bar (Filter/Sort + View toggle) ────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _TopBarDelegate(
                  status: _filterStatus,
                  isGridView: _isGridView,
                  onStatusChanged: (s) {
                    setState(() {
                      _filterStatus = s;
                      _visibleCount = _kPageSize; // reset lazy loading
                    });
                  },
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
    if (state.isLoadingEvents) {
      return _isGridView ? _buildGridShimmer() : _buildListShimmer();
    }

    final filtered = _getFilteredList(state.popularEvents);
    if (filtered.isEmpty) {
      return _buildEmpty();
    }

    final events = _sliced(state.popularEvents);
    return _isGridView
        ? _buildGrid(context, events, filtered.length)
        : _buildList(context, events, filtered.length);
  }

  // ── Grid ───────────────────────────────────────────────────────────────────
  Widget _buildGrid(
    BuildContext context,
    List<EventModel> events,
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
      itemCount: events.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (ctx, i) {
        if (i >= events.length) {
          return const ShimmerBox(radius: 12);
        }
        return AppAnimations.fadeIn(
          duration: Duration(milliseconds: 300 + (i * 40)),
          child: _EventGridCard(
            event: events[i],
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                ctx,
                RouteNames.eventDetails,
                arguments: {'id': events[i].id, 'event': events[i]},
              );
            },
          ),
        );
      },
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList(
    BuildContext context,
    List<EventModel> events,
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
      itemCount: events.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= events.length) {
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
            child: _EventListCard(
              event: events[i],
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pushNamed(
                  ctx,
                  RouteNames.eventDetails,
                  arguments: {'id': events[i].id, 'event': events[i]},
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
        height: 270,
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
              Icons.event_busy_rounded,
              size: 56,
              color: appGreyLight,
            ),
          ),
          const SizedBox(height: 20),
          AppText.subHeading(
            'No ${_filterStatus.capitalize()} Events',
            size: 18,
            fontWeight: FontWeight.w800,
            color: appGrey,
          ),
          const SizedBox(height: 8),
          AppText.body(
            'Try switching to a different tab',
            color: appGrey,
            size: 13,
          ),
        ],
      ),
    );
  }
}

// ─── Sticky Top Bar Delegate ──────────────────────────────────────────────────
class _TopBarDelegate extends SliverPersistentHeaderDelegate {
  final String status;
  final bool isGridView;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onViewToggle;

  const _TopBarDelegate({
    required this.status,
    required this.isGridView,
    required this.onStatusChanged,
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
          // ── Status dropdown (Left) ──────────────────────────────────────
          _StatusDropdown(status: status, onChanged: onStatusChanged),

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
      old.status != status || old.isGridView != isGridView;
}

// ─── Inline Status Dropdown ───────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  final String status;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({required this.status, required this.onChanged});

  String _label(String value) {
    switch (value) {
      case 'upcoming':
        return 'Upcoming';
      case 'live':
        return 'Live';
      case 'completed':
        return 'Completed';
      default:
        return 'Events';
    }
  }

  IconData _icon(String value) {
    switch (value) {
      case 'upcoming':
        return Icons.calendar_month_rounded;
      case 'live':
        return Icons.stream_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      default:
        return Icons.event;
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
          value: status,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryBlue,
            size: 16,
          ),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primaryBlue,
          ),
          dropdownColor: appWhite,
          borderRadius: BorderRadius.circular(12),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: ['upcoming', 'live', 'completed']
              .map(
                (v) => DropdownMenuItem<String>(
                  value: v,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon(v), size: 14, color: primaryBlue),
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

// ─── Event Grid Card ──────────────────────────────────────────────────────────
class _EventGridCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventGridCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColorLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ShimmerBox(),
                errorWidget: (_, _, _) => Container(
                  color: appGreyVeryLight,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: appGrey,
                  ),
                ),
              ),
              // Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
              // Floating Date Tag Right Top
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: appWhite,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat.MMMd().format(event.date),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: appWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Text Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: appWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AppText.caption(
                          event.category.toUpperCase(),
                          color: appWhite.withValues(alpha: 0.9),
                          size: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppText.body(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AppText.caption(
                              event.venue,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Event List Card (Package Style) ──────────────────────────────────────────
class _EventListCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventListCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image ──────────────────────────────────────────────
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ShimmerBox(height: 180),
                      errorWidget: (_, _, _) => Container(
                        height: 180,
                        color: onboardingBlueVeryLight,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: appGreyLight,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                    // Simple bottom gradient for readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Category pill (bottom-right) ────────
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Card body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A2E),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Location
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: appGrey,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: AppText.caption(
                                        event.venue,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        color: appGrey,
                                        size: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                event.entryFee == 'Free'
                                    ? 'Free'
                                    : '₹${event.entryFee}',
                                style: TextStyle(
                                  color: event.entryFee == 'Free'
                                      ? Colors.green.shade700
                                      : primaryBlue,
                                  fontSize: event.entryFee == 'Free' ? 14 : 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (event.entryFee != 'Free')
                                const Text(
                                  'entry fee',
                                  style: TextStyle(
                                    color: appGrey,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Stats Row
                      Row(
                        children: [
                          _EventInfoChip(
                            icon: Icons.calendar_month_rounded,
                            label: DateFormat.MMMd().format(event.date),
                          ),
                          const SizedBox(width: 8),
                          _EventInfoChip(
                            icon: Icons.access_time_filled_rounded,
                            label: event.startTime,
                            color: const Color(0xFFE9A21B), // orange/amber
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: appGreyLight,
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
}

// ── Event Info Chip
class _EventInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _EventInfoChip({
    required this.icon,
    required this.label,
    this.color = primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
