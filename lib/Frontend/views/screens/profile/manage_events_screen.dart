import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/models/event_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/events_service.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:http/http.dart' as http;
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final EventsService _eventsService = EventsService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await _eventsService.getEvents();
      // Sort by date ascending (closest events first)
      events.sort((a, b) => a.date.compareTo(b.date));
      
      if (!mounted) return;
      setState(() {
        _allEvents = events;
        _filteredEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterEvents(String query) {
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final title = event.title.toLowerCase();
        final venue = event.venue.toLowerCase();
        return title.contains(query.toLowerCase()) ||
            venue.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSearchBox(),
          _buildList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            RouteNames.addEvent,
          );
          if (result == true) _fetchEvents();
        },
        backgroundColor: primaryBlue,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: 'Add New Event',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: onboardingBlueVeryLight,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: appBlack,
          size: 20,
        ),
      ),
      title: AppText.heading(
        "Manage Events",
        size: 22,
        fontWeight: FontWeight.w900,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _fetchEvents,
          icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBox() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterEvents,
            decoration: InputDecoration(
              hintText: "Search your events...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: primaryBlue,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              AppText.body("Error loading events", fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _fetchEvents,
                child: const Text("Retry Now"),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              AppText.body("No events found", color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildEventCard(_filteredEvents[index]),
          childCount: _filteredEvents.length,
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          RouteNames.eventDetails,
          arguments: {'id': event.id, 'event': event},
        );

        if (result is EventModel && mounted) {
          setState(() {
            final allIdx = _allEvents.indexWhere((e) => e.id == result.id);
            if (allIdx != -1) _allEvents[allIdx] = result;

            final filterIdx =
                _filteredEvents.indexWhere((e) => e.id == result.id);
            if (filterIdx != -1) _filteredEvents[filterIdx] = result;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerBox(),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${event.interestedCount}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText.small(
                        event.category.toUpperCase(),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subHeading(
                            event.title,
                            size: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.grey,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: AppText.caption(
                                  event.venue,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: primaryBlue,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              AppText.caption(
                                DateFormat('dd MMM yyyy').format(event.date),
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildActionMenu(event),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(EventModel event) {
    return PopupMenuButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onboardingBlueVeryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: primaryBlue,
          size: 20,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 20, color: primaryBlue),
              const SizedBox(width: 10),
              AppText.body("Edit Event"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 10),
              AppText.body("Delete Event", color: Colors.redAccent),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'delete') _confirmDelete(event);
      },
    );
  }

  void _confirmDelete(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: AppText.subHeading("Delete Event?"),
        content: AppText.body(
          "Are you sure you want to remove '${event.title}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteEvent(event.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(String id) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/events/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
        }
        _fetchEvents();
      } else {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
