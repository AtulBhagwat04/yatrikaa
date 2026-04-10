import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/event_model.dart';
import 'package:yatrikaa/Frontend/core/services/events_service.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/custom_alert_dialog.dart';
import 'package:yatrikaa/Frontend/core/utils/error_handler.dart';
import 'package:http/http.dart' as http;
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_location_field.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final EventsService _eventsService = EventsService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isMoreLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isMoreLoading && _hasMore && !_isLoading) {
        _loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents({bool refresh = true}) async {
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _isLoading = true;
        _currentPage = 1;
      } else {
        _isMoreLoading = true;
      }
      _error = null;
    });

    try {
      final res = await _eventsService.getEventsPaginated(
        page: _currentPage,
        limit: 12,
      );
      final List<EventModel> events = res['events'] ?? [];
      final bool hasMore = res['hasMore'] ?? false;

      if (!mounted) return;
      setState(() {
        if (refresh) {
          _allEvents = events;
        } else {
          // Avoid duplicates if any
          for (var e in events) {
            if (!_allEvents.any((existing) => existing.id == e.id)) {
              _allEvents.add(e);
            }
          }
        }
        // Sort by date ascending (closest events first)
        _allEvents.sort((a, b) => a.date.compareTo(b.date));
        _filteredEvents = _allEvents;
        _hasMore = hasMore;
        _isLoading = false;
        _isMoreLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadMore() {
    if (_hasMore && !_isMoreLoading && !_isLoading) {
      _currentPage++;
      _fetchEvents(refresh: false);
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
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetchEvents,
          displacement: 80,
          color: primaryBlue,
          child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(),
            _buildSearchBox(),
            _buildList(),
            if (_hasMore || _isMoreLoading) _buildLoadMoreIndicator(),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
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
      title: AppText.heading(
        "Manage Events",
        size: 22,
        fontWeight: FontWeight.w900,
      ),
      centerTitle: true,
      bottom: _isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: onboardingBlueVeryLight,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            )
          : null,
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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
            child: ModernSearchBar(
              controller: _searchController,
              onChanged: _filterEvents,
              suggestionsEnabled: false,
              hint: "Search your events...",
              icon: Icons.search_rounded,
            ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading && _allEvents.isEmpty) {
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
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildEventCard(_filteredEvents[index]);
        }, childCount: _filteredEvents.length),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: _isMoreLoading
              ? const CircularProgressIndicator(
                  color: primaryBlue,
                  strokeWidth: 3,
                )
              : const SizedBox.shrink(),
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
          _refreshSingleEvent(result.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                    placeholder: (_, _) => const ShimmerBox(),
                    errorWidget: (_, _, _) => Container(
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
                    child: Row(
                      children: [
                        _buildCircularButton(
                          icon: Icons.edit,
                          color: Colors.white,
                          onTap: () => _editEvent(event),
                          tooltip: 'Edit Event',
                        ),
                        const SizedBox(width: 8),
                        _buildCircularButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          isDestructive: true,
                          onTap: () => _confirmDelete(event),
                          tooltip: 'Delete Event',
                        ),
                      ],
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: AppText.subHeading(
                                  event.title,
                                  size: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: onboardingBlueVeryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people_alt_rounded,
                                      color: primaryBlue,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${event.interestedCount}",
                                      style: GoogleFonts.montserrat(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.white
                : Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : color,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(EventModel event) {
    CustomAlertDialog.show(
      context,
      title: 'Delete Event?',
      message:
          "Are you sure you want to remove '${event.title}'? This action cannot be undone.",
      confirmLabel: 'Delete',
      type: CustomAlertType.error,
      icon: Icons.delete_forever_rounded,
      onConfirm: () => _deleteEvent(event.id),
    );
  }

  void _editEvent(EventModel event) {
    final titleController = TextEditingController(text: event.title);
    final venueController = TextEditingController(text: event.venue);
    final addressController = TextEditingController(text: event.address);
    final descriptionController = TextEditingController(
      text: event.description,
    );
    final latController = TextEditingController(text: event.lat.toString());
    final lngController = TextEditingController(text: event.lng.toString());

    DateTime selectedDate = event.date;
    String selectedCategory = event.category;

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    try {
      if (event.startTime.isNotEmpty) {
        final dt = DateFormat.jm().parse(event.startTime);
        startTime = TimeOfDay.fromDateTime(dt);
      }
      if (event.endTime != null && event.endTime!.isNotEmpty) {
        final dt = DateFormat.jm().parse(event.endTime!);
        endTime = TimeOfDay.fromDateTime(dt);
      }
    } catch (e) {
      debugPrint("Time parsing error: $e");
    }

    List<String> existingImages = List.from(event.images);
    List<XFile> pickedFiles = [];

    final categories = [
      'Cultural',
      'Festival',
      'Adventure',
      'Spiritual',
      'Exhibition',
      'Workshop',
      'Concert',
      'Food Fair',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSheetLoading = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Drag Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.heading(
                          "Edit Event",
                          size: 20,
                          fontWeight: FontWeight.w900,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subHeading(
                            "MANAGE GALLERY",
                            size: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...existingImages.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  String url = entry.value;
                                  return Container(
                                    width: 130,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: url,
                                            height: 150,
                                            width: 130,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) =>
                                                const ShimmerBox(),
                                            errorWidget: (_, _, _) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: GestureDetector(
                                            onTap: () {
                                              if (existingImages.length == 1 &&
                                                  pickedFiles.isEmpty) {
                                                CustomToast.warning(
                                                  context,
                                                  "At least one image is required",
                                                  title: "Wait!",
                                                );
                                                return;
                                              }
                                              setSheetState(
                                                () =>
                                                    existingImages.removeAt(idx),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                ...pickedFiles.asMap().entries.map((entry) {
                                  return Container(
                                    width: 130,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(entry.value.path),
                                            height: 150,
                                            width: 130,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: GestureDetector(
                                            onTap: () => setSheetState(
                                              () =>
                                                  pickedFiles.removeAt(entry.key),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                if (existingImages.length + pickedFiles.length <
                                    10)
                                  GestureDetector(
                                    onTap: () async {
                                      final List<XFile> images = await _picker
                                          .pickMultiImage(imageQuality: 70);
                                      if (images.isNotEmpty) {
                                        setSheetState(() {
                                          int remaining =
                                              10 -
                                              (existingImages.length +
                                                  pickedFiles.length);
                                          pickedFiles.addAll(
                                            images.take(remaining),
                                          );
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 130,
                                      decoration: BoxDecoration(
                                        color: onboardingBlueVeryLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryBlue.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            color: primaryBlue.withOpacity(0.6),
                                            size: 32,
                                          ),
                                          const SizedBox(height: 8),
                                          AppText.caption(
                                            "Add Photo",
                                            color: primaryBlue,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          AppText.subHeading(
                            "EVENT INFO",
                            size: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 16),
                          _buildSheetField(
                            "Event Title",
                            titleController,
                            Icons.title_rounded,
                          ),
                          _buildSheetDropdown(
                            "Category",
                            selectedCategory,
                            categories,
                            (val) {
                              if (val != null) {
                                setSheetState(() => selectedCategory = val);
                              }
                            },
                          ),
                          _buildSheetField(
                            "Description",
                            descriptionController,
                            Icons.notes_rounded,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          AppText.subHeading(
                            "LOCATION",
                            size: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 16),
                          ModernLocationField(
                            controller: venueController,
                            label: "Venue / City",
                            hint: "Search and select venue",
                            onSelected: (place) {
                              venueController.text = place.name;
                              // Optionally update address/lat/lng if requested
                            },
                          ),
                          const SizedBox(height: 16),
                          ModernLocationField(
                            controller: addressController,
                            label: "Address",
                            hint: "Full address",
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSheetField(
                                  "Latitude",
                                  latController,
                                  Icons.gps_fixed_rounded,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSheetField(
                                  "Longitude",
                                  lngController,
                                  Icons.gps_fixed_rounded,
                                  isNumber: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppText.subHeading(
                            "SCHEDULE",
                            size: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 16),
                          _buildSheetPickerSelector(
                            "Event Date",
                            DateFormat('dd MMM, yyyy').format(selectedDate),
                            Icons.calendar_today_rounded,
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 1000),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSheetPickerSelector(
                                  "Start Time",
                                  _formatTimeOfDay(startTime),
                                  Icons.access_time_rounded,
                                  () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: startTime,
                                    );
                                    if (picked != null) {
                                      setSheetState(() => startTime = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSheetPickerSelector(
                                  "End Time",
                                  _formatTimeOfDay(endTime),
                                  Icons.access_time_rounded,
                                  () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: endTime,
                                    );
                                    if (picked != null) {
                                      setSheetState(() => endTime = picked);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isSheetLoading
                                  ? () {}
                                  : () async {
                                      if (existingImages.isEmpty &&
                                          pickedFiles.isEmpty) {
                                        CustomToast.warning(
                                          context,
                                          "At least one image is required",
                                          title: "Wait!",
                                        );
                                        return;
                                      }

                                      setSheetState(() => isSheetLoading = true);
                                      final success = await _handleUpdate(
                                        event.id,
                                        {
                                          'title': titleController.text.trim(),
                                          'description': descriptionController.text
                                              .trim(),
                                          'venue': venueController.text.trim(),
                                          'address': addressController.text.trim(),
                                          'category': selectedCategory,
                                          'date': selectedDate.toIso8601String(),
                                          'startTime': _formatTimeOfDay(startTime),
                                          'endTime': _formatTimeOfDay(endTime),
                                          'geometry': {
                                            'location': {
                                              'lat':
                                                  double.tryParse(latController.text) ??
                                                  0.0,
                                              'lng':
                                                  double.tryParse(lngController.text) ??
                                                  0.0,
                                            },
                                          },
                                          'images': existingImages,
                                        },
                                        pickedFiles.map((x) => File(x.path)).toList(),
                                      );

                                      if (success && mounted) {
                                        Navigator.pop(ctx);
                                      } else if (mounted) {
                                        setSheetState(() => isSheetLoading = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: primaryBlue,
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isSheetLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : AppText.button(
                                      "Update Event Info",
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int? maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.caption(
            label.toUpperCase(),
            size: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryBlue, size: 18),
              filled: true,
              fillColor: onboardingBlueVeryLight.withOpacity(0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.caption(
            label.toUpperCase(),
            size: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: onboardingBlueVeryLight.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.first,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetPickerSelector(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.caption(
            label.toUpperCase(),
            size: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: onboardingBlueVeryLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: primaryBlue, size: 18),
                  const SizedBox(width: 12),
                  Text(value, style: GoogleFonts.montserrat(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<bool> _handleUpdate(
    String id,
    Map<String, dynamic> body,
    List<File> images,
  ) async {
    try {
      final success = await _eventsService.updateEvent(
        id,
        body,
        imageFiles: images,
      );
      if (success && mounted) {
        CustomToast.success(context, "Event details updated successfully!");
        _refreshSingleEvent(id);
        return true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
      return false;
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        CustomToast.success(context, 'Event deleted successfully');
        setState(() {
          _allEvents.removeWhere((e) => e.id == eventId);
          _filterEvents(_searchController.text);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshSingleEvent(String id) async {
    try {
      final updatedEvent = await _eventsService.getEventDetails(id);
      if (updatedEvent == null || !mounted) return;

      setState(() {
        final index = _allEvents.indexWhere((e) => e.id == id);
        if (index != -1) {
          _allEvents[index] = updatedEvent;
        }
        _filterEvents(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      print('[ManageEvents] Error refreshing single event: $e');
      _fetchEvents();
    }
  }
}
