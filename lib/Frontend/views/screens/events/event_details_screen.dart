import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/app_assets.dart';
import 'package:yatrikaa/Frontend/core/models/event_model.dart';
import 'package:yatrikaa/Frontend/core/services/events_service.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/external_action_card.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final EventModel? event;

  const EventDetailsScreen({super.key, required this.eventId, this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventsService _eventsService = EventsService();
  late Future<EventModel?> _eventFuture;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  bool _showAppBarTitle = false;
  bool _isDescriptionExpanded = false;
  EventModel? _currentEvent;
  bool _isInterestedLoading = false;
  String? _userId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _currentEvent = widget.event;
      _eventFuture = Future.value(widget.event);
      // Refresh details in background to ensure latest state (e.g. interested count)
      _eventsService.getEventDetails(widget.eventId).then((e) {
        if (mounted && e != null) {
          setState(() => _currentEvent = e);
        }
      });
    } else {
      _eventFuture = _eventsService.getEventDetails(widget.eventId).then((e) {
        if (mounted) setState(() => _currentEvent = e);
        return e;
      });
    }

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showAppBarTitle) {
        setState(() => _showAppBarTitle = true);
      } else if (_scrollController.offset <= 300 && _showAppBarTitle) {
        setState(() => _showAppBarTitle = false);
      }
    });

    _fetchUserId();

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      final evt = _currentEvent;
      if (evt != null && evt.images.length > 1 && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchUserId() async {
    final authService = AuthService();
    final id = await authService.getUserId();
    if (mounted) {
      setState(() => _userId = id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  void _shareEvent(EventModel event) {
    Share.share(
      'Check out this event: ${event.title}\nDate: ${DateFormat.yMMMd().format(event.date)}\nVenue: ${event.venue}\nDetails on Yatrikaa!',
    );
  }

  DateTime _combineDateAndTime(DateTime date, String timeString) {
    try {
      // DateFormat.jm() parses "10:00 AM" or "5:00 PM"
      final timeFormat = DateFormat.jm();
      final time = timeFormat.parse(timeString);
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } catch (e) {
      // If parsing fails, use the date at 00:00
      return DateTime(date.year, date.month, date.day);
    }
  }

  String _getEventStatus(EventModel event) {
    final now = DateTime.now();

    // Start time of the event
    final startDateTime = _combineDateAndTime(event.date, event.startTime);

    // End time: if not specified, assume 4 hours duration or until end of day
    DateTime endDateTime;
    if (event.endTime != null && event.endTime!.isNotEmpty) {
      endDateTime = _combineDateAndTime(event.date, event.endTime!);
      // If end time is technically before start time (e.g. starts 10 PM, ends 2 AM),
      // it means it ends the next day.
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
    } else {
      // Default duration of 4 hours if no end time
      endDateTime = startDateTime.add(const Duration(hours: 4));

      // If it's already past endDateTime, but it's still the same day,
      // maybe we should keep it as "Happening Now" if it's a day-long event?
      // Actually, if it's past midnight of the event day, it's definitely ended.
    }

    if (now.isAfter(endDateTime)) {
      return "Event Ended";
    } else if (now.isAfter(startDateTime) ||
        now.isAtSameMomentAs(startDateTime)) {
      return "Happening Now";
    } else {
      final difference = startDateTime.difference(now);
      if (difference.inDays > 0) {
        return "${difference.inDays} days left";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} hrs left";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} mins left";
      } else {
        return "Starting soon";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventModel?>(
      future: _eventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: onboardingBlueVeryLight,
            body: Center(child: CircularProgressIndicator(color: primaryBlue)),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text("Error"),
            ),
            body: const Center(child: Text("Event not found")),
          );
        }

        return Scaffold(
          backgroundColor: onboardingBlueVeryLight,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeroSection(_currentEvent ?? event),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(color: appWhite),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Title & Overview
                          Container(
                            padding: const EdgeInsets.only(
                              top: 24,
                              left: 20,
                              right: 20,
                              bottom: 10,
                            ),
                            decoration: const BoxDecoration(
                              color: onboardingBlueVeryLight,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitleSection(_currentEvent ?? event),
                                const SizedBox(height: 20),
                                _buildInterestedBadge(_currentEvent ?? event),
                                const SizedBox(height: 20),
                                _buildFeaturesSection(_currentEvent ?? event),
                              ],
                            ),
                          ),

                          // Section 2: Event Description
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _buildDescriptionSection(
                              _currentEvent ?? event,
                            ),
                          ),

                          // Section 3: Location & Organizer
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMapSection(_currentEvent ?? event),
                                const SizedBox(height: 24),
                                _buildOrganizerSection(_currentEvent ?? event),
                                const SizedBox(
                                  height: 100,
                                ), // Adjusted bottom spacing
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildStickyHeader(_currentEvent ?? event),
              _buildBottomAction(_currentEvent ?? event),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleInterest(String eventId) async {
    if (_isInterestedLoading || _userId == null) return;

    // Optimistic UI update to trigger horizontal shrink animation immediately
    final oldEvent = _currentEvent;
    if (oldEvent != null) {
      final isNowInterested = !oldEvent.interestedUsers.contains(_userId);
      final newUsers = List<String>.from(oldEvent.interestedUsers);
      if (isNowInterested) {
        newUsers.add(_userId!);
      } else {
        newUsers.remove(_userId!);
      }

      setState(() {
        _currentEvent = oldEvent.copyWith(
          interestedUsers: newUsers,
          interestedCount:
              (oldEvent.interestedCount + (isNowInterested ? 1 : -1))
                  .clamp(0, 999999)
                  .toInt(),
        );
        _isInterestedLoading = true;
      });
    }

    try {
      final updatedEvent = await _eventsService.toggleInterest(eventId);
      if (mounted) {
        setState(() {
          if (updatedEvent != null) {
            _currentEvent = updatedEvent;
          } else {
            // Rollback on failure
            _currentEvent = oldEvent;
          }
          _isInterestedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentEvent = oldEvent;
          _isInterestedLoading = false;
        });
      }
    }
  }

  Widget _buildStickyHeader(EventModel event) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 93,
        padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
        decoration: BoxDecoration(
          color: _showAppBarTitle ? appWhite : Colors.transparent,
          boxShadow: _showAppBarTitle
              ? [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            _circularHeaderButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
              isLight: !_showAppBarTitle,
            ),
            if (_showAppBarTitle)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 16),
                  child: AppAnimations.fadeIn(
                    child: AppText.subHeading(
                      event.title,
                      maxLines: 1,
                      align: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            _circularHeaderButton(
              icon: Icons.share_rounded,
              onPressed: () => _shareEvent(event),
              isLight: !_showAppBarTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black,
    bool isLight = false,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: isLight ? appWhite : iconColor,
        size: 24,
        shadows: isLight
            ? [
                const BoxShadow(
                  color: shadowColor,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildHeroSection(EventModel event) {
    final images = event.images.isEmpty
        ? [AppAssets.placeholderImageUrl]
        : event.images;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 400,
      backgroundColor: appBlack,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.length <= 1 ? images.length : null,
              itemBuilder: (context, index) {
                final realIndex = images.isNotEmpty ? index % images.length : 0;
                return CachedNetworkImage(
                  imageUrl: images[realIndex],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerBox(),
                  errorWidget: (context, url, error) => Container(
                    color: appGreyVeryLight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported_outlined,
                          color: appGrey,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "Image not available",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: appGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      appBlack.withAlpha(120),
                      Colors.transparent,
                      appBlack.withAlpha(200),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 15,
              child: ListenableBuilder(
                listenable: _scrollController,
                builder: (context, child) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  final opacity = (1.0 - (offset / 300)).clamp(0.0, 1.0);
                  final slide = -offset * 0.15;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, slide),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.heading(
                            event.title,
                            color: appWhite,
                            fontWeight: FontWeight.w900,
                            size: 28,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AppText.heading(
                event.title,
                fontWeight: FontWeight.w900,
                size: 26, // Increased size for better hierarchy
              ),
            ),
            _statusBadge(event),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: primaryBlue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: AppText.body(
                event.venue,
                color: appGrey,
                fontWeight: FontWeight.w600,
                size: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(EventModel event) {
    final status = _getEventStatus(event);
    final isLive = status == "Happening Now";
    final isEnded = status == "Event Ended";

    Color badgeColor;
    Color textColor;

    if (isLive) {
      badgeColor = errorColor.withAlpha(20);
      textColor = errorColor;
    } else if (isEnded) {
      badgeColor = appGrey.withAlpha(20);
      textColor = appGrey;
    } else {
      // Upcoming
      badgeColor = successColor.withAlpha(20);
      textColor = successColor;
    }

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (event.isPopular) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: primaryBlue.withAlpha(50),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: primaryBlue, size: 10),
                  const SizedBox(width: 4),
                  AppText.caption(
                    "POPULAR",
                    color: primaryBlue,
                    fontWeight: FontWeight.w900,
                    size: 9,
                    letterSpacing: 0.5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: textColor.withAlpha(40), width: 0.5),
            ),
            child: Center(
              child: AppText.caption(
                status.toUpperCase(),
                color: textColor,
                fontWeight: FontWeight.w800,
                size: 9, // Matched with Popular tag size
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestedBadge(EventModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 24,
            child: Stack(
              children: List.generate(3, (index) {
                return Positioned(
                  left: index * 16.0,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: appWhite,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/100?u=${index + 20}',
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 4),
          AppText.small(
            "${event.interestedCount}+ people are interested",
            color: appGrey,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(EventModel event) {
    String entryFeeText = event.entryFee.trim();
    if (entryFeeText.isEmpty || entryFeeText.toLowerCase() == 'free') {
      entryFeeText = 'Free';
    } else {
      // If it's a pure number or doesn't have the symbol yet, add it
      final isNumeric = RegExp(r'^\d+$').hasMatch(entryFeeText);
      if (isNumeric && !entryFeeText.contains('₹')) {
        entryFeeText = '₹$entryFeeText';
      }
    }

    final List<(IconData, String)> features = [
      (Icons.calendar_month_rounded, DateFormat('dd MMM').format(event.date)),
      (Icons.access_time_rounded, event.startTime),
      (Icons.currency_rupee_rounded, entryFeeText),
    ];

    return Row(
      children: features.map((feature) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: onboardingBlueVeryLight.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(feature.$1, size: 18, color: primaryBlue),
                const SizedBox(height: 6),
                AppText.small(
                  feature.$2,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionSection(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(
          "Event Description",
          fontWeight: FontWeight.w800,
          size: 22,
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(
              event.description,
              color: appGreyDark,
              align: TextAlign.justify,
              size: 14,
              height: 1.6,
              maxLines: _isDescriptionExpanded ? null : 6,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (event.description.length > 200) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.body(
                      _isDescriptionExpanded ? "Read Less" : "Read Full Story",
                      color: primaryBlue,
                      fontWeight: FontWeight.w800,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isDescriptionExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: primaryBlue,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildOrganizerSection(EventModel event) {
    return InkWell(
      onTap: () => _showContactBottomSheet(event),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AppText.body(
                          event.organizer ?? "Official Host",
                          fontWeight: FontWeight.w900,
                          size: 15,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: primaryBlue,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  AppText.caption(
                    "View Contact Information",
                    color: primaryBlue,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showContactBottomSheet(EventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppText.subHeading("Organized By", fontWeight: FontWeight.w900),
            const SizedBox(height: 8),
            AppText.heading(
              event.organizer ?? "Official Host",
              size: 24,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: 24),
            if (event.contactNumber != null)
              _bottomSheetAction(
                icon: Icons.phone_in_talk_rounded,
                title: "Call Organizer",
                subtitle: event.contactNumber!,
                onTap: () => _launchUrl('tel:${event.contactNumber}'),
                color: Colors.green,
              ),
            if (event.website != null) ...[
              const SizedBox(height: 12),
              _bottomSheetAction(
                icon: Icons.public_rounded,
                title: "Official Website",
                subtitle: "Visit event page",
                onTap: () => _launchUrl(event.website!),
                color: primaryBlue,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(title, fontWeight: FontWeight.w900),
                  AppText.caption(subtitle, color: Colors.grey[600]),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading("Location", fontWeight: FontWeight.w800, size: 22),
        const SizedBox(height: 12),
        ExternalActionCard(
          title: event.venue,
          subtitle: event.address,
          icon: Icons.directions_rounded,
          onTap: () => _launchUrl(
            'https://www.google.com/maps/dir/?api=1&destination=${event.lat},${event.lng}',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(EventModel event) {
    final status = _getEventStatus(event);
    final isEnded = status == "Event Ended";
    final isInterested = event.interestedUsers.contains(_userId);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        color: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                ...previousChildren,
                ?currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                axisAlignment: 1.0,
                child: child,
              ),
            );
          },
          child: (isInterested && !isEnded)
              ? _buildFloatingHeart(event)
              : _buildFullWidthButton(event, isEnded),
        ),
      ),
    );
  }

  Widget _buildFloatingHeart(EventModel event) {
    return Container(
      key: const ValueKey('liked_heart'),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: _isInterestedLoading ? null : () => _toggleInterest(event.id),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: _isInterestedLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : AppAnimations.fadeIn(
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFullWidthButton(EventModel event, bool isEnded) {
    return Container(
      key: const ValueKey('main_button'),
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: isEnded ? Colors.grey : primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isEnded ? Colors.grey : primaryBlue).withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isInterestedLoading || isEnded)
            ? null
            : () => _toggleInterest(event.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isInterestedLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText.button(
                    isEnded ? "EVENT ENDED" : "I'M INTERESTED",
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ],
              ),
      ),
    );
  }
}
