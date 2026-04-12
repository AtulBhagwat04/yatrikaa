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
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/external_action_card.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/core/utils/app_animations.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';

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
      if (_scrollController.hasClients) {
        if (_scrollController.offset > 300 && !_showAppBarTitle) {
          setState(() => _showAppBarTitle = true);
        } else if (_scrollController.offset <= 300 && _showAppBarTitle) {
          setState(() => _showAppBarTitle = false);
        }
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
        CustomToast.error(context, 'Could not launch $urlString');
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
      final timeFormat = DateFormat.jm();
      final time = timeFormat.parse(timeString);
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } catch (e) {
      return DateTime(date.year, date.month, date.day);
    }
  }

  String _getEventStatus(EventModel event) {
    final now = DateTime.now();
    final startDateTime = _combineDateAndTime(event.date, event.startTime);

    DateTime endDateTime;
    if (event.endTime != null && event.endTime!.isNotEmpty) {
      endDateTime = _combineDateAndTime(event.date, event.endTime!);
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
    } else {
      endDateTime = startDateTime.add(const Duration(hours: 4));
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

  Future<void> _toggleInterest(String eventId) async {
    if (_isInterestedLoading || _userId == null) return;

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

      try {
        final updatedEvent = await _eventsService.toggleInterest(eventId);
        if (mounted) {
          setState(() {
            if (updatedEvent != null) {
              _currentEvent = updatedEvent;
            } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventModel?>(
      future: _eventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: appWhite,
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

        return _EventDetailsView(
          event: _currentEvent ?? event,
          scrollController: _scrollController,
          pageController: _pageController,
          showAppBarTitle: _showAppBarTitle,
          isDescriptionExpanded: _isDescriptionExpanded,
          isInterestedLoading: _isInterestedLoading,
          userId: _userId,
          onToggleInterest: () => _toggleInterest(widget.eventId),
          onRefresh: () async {
            final updated = await _eventsService.getEventDetails(
              widget.eventId,
            );
            if (mounted && updated != null) {
              setState(() {
                _currentEvent = updated;
                _eventFuture = Future.value(updated);
              });
            }
          },
          onShare: () => _shareEvent(_currentEvent ?? event),
          onDescriptionToggle: () {
            setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
          },
          onLaunchUrl: _launchUrl,
          getEventStatus: _getEventStatus,
        );
      },
    );
  }
}

class _EventDetailsView extends StatelessWidget {
  final EventModel event;
  final ScrollController scrollController;
  final PageController pageController;
  final bool showAppBarTitle;
  final bool isDescriptionExpanded;
  final bool isInterestedLoading;
  final String? userId;
  final VoidCallback onToggleInterest;
  final RefreshCallback onRefresh;
  final VoidCallback onShare;
  final VoidCallback onDescriptionToggle;
  final Function(String) onLaunchUrl;
  final String Function(EventModel) getEventStatus;

  const _EventDetailsView({
    required this.event,
    required this.scrollController,
    required this.pageController,
    required this.showAppBarTitle,
    required this.isDescriptionExpanded,
    required this.isInterestedLoading,
    this.userId,
    required this.onToggleInterest,
    required this.onRefresh,
    required this.onShare,
    required this.onDescriptionToggle,
    required this.onLaunchUrl,
    required this.getEventStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appWhite,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        color: primaryBlue,
        child: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildHeroSection(),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(color: appWhite),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.m,
                            AppSpacing.m,
                            AppSpacing.m,
                            AppSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitleSection(),
                              const SizedBox(height: AppSpacing.m),
                              _buildFeaturesSection(),
                            ],
                          ),
                        ),
                        _buildSectionDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.xs,
                          ),
                          child: _buildInterestedBadge(),
                        ),
                        _buildSectionDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.xs,
                          ),
                          child: _buildDescriptionSection(),
                        ),
                        _buildSectionDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMapSection(),
                              const SizedBox(height: AppSpacing.l),
                              _buildOrganizerSection(context),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildStickyHeader(context),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 85,
        padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
        decoration: BoxDecoration(
          color: showAppBarTitle ? appWhite : Colors.transparent,
          boxShadow: showAppBarTitle
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            _circularHeaderButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
              isLight: !showAppBarTitle,
            ),
            if (showAppBarTitle)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 16),
                  child: AppAnimations.fadeIn(
                    child: AppText.subHeading(
                      event.title,
                      maxLines: 1,
                      fontWeight: FontWeight.w800,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            _circularHeaderButton(
              icon: Icons.share_rounded,
              onPressed: onShare,
              isLight: !showAppBarTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            appGreyLight.withAlpha(0),
            appGreyLight,
            appGreyLight,
            appGreyLight.withAlpha(0),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _circularHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isLight = false,
  }) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        icon,
        color: isLight ? appWhite : appBlack,
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

  Widget _buildHeroSection() {
    final images = event.images.isEmpty
        ? [AppAssets.placeholderImageUrl]
        : event.images;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 320,
      backgroundColor: appWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: images.length <= 1 ? images.length : null,
              itemBuilder: (context, index) {
                final realIndex = images.isNotEmpty ? index % images.length : 0;
                return CachedNetworkImage(
                  imageUrl: images[realIndex],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerBox(),
                  errorWidget: (context, url, error) => _imageError(),
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
                      appBlack.withAlpha(80),
                      Colors.transparent,
                      appBlack.withAlpha(180),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: ListenableBuilder(
                listenable: scrollController,
                builder: (context, child) {
                  final offset = scrollController.hasClients
                      ? scrollController.offset
                      : 0.0;
                  final opacity = (1.0 - (offset / 250)).clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.heading(
                          event.title,
                          color: appWhite,
                          fontWeight: FontWeight.w900,
                          size: 26,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _imageError() {
    return Container(
      color: appGreyVeryLight,
      child: const Center(
        child: Icon(Icons.image_not_supported, color: appGrey),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppText.heading(
                event.title,
                fontWeight: FontWeight.w900,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            _statusBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: primaryBlue, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppText.body(
                event.venue,
                color: appGrey,
                fontWeight: FontWeight.w600,
                size: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge() {
    final status = getEventStatus(event);
    final isLive = status == "Happening Now";
    final isEnded = status == "Event Ended";

    Color badgeColor;
    Color textColor;

    if (isLive) {
      badgeColor = Colors.red.withAlpha(20);
      textColor = Colors.red;
    } else if (isEnded) {
      badgeColor = appGrey.withAlpha(20);
      textColor = appGrey;
    } else {
      badgeColor = Colors.green.withAlpha(20);
      textColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (event.isPopular) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primaryBlue.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: primaryBlue.withAlpha(50), width: 0.5),
            ),
            child: Row(
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
          child: AppText.caption(
            status.toUpperCase(),
            color: textColor,
            fontWeight: FontWeight.w800,
            size: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestedBadge() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appGreyLight),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            height: 28,
            child: Stack(
              children: List.generate(
                (event.interestedUsers.length > 3
                    ? 3
                    : event.interestedUsers.length),
                (index) {
                  return Positioned(
                    left: index * 18.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: appWhite, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: primaryBlue.withAlpha(30),
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/100?u=${event.id}_$index',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: AppText.body(
              "${event.interestedCount}+ enthusiasts attending",
              color: appBlack,
              fontWeight: FontWeight.w700,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    String entryFeeText = event.entryFee.trim();
    if (entryFeeText.isEmpty || entryFeeText.toLowerCase() == 'free') {
      entryFeeText = 'Free';
    } else {
      final isNumeric = RegExp(r'^\d+$').hasMatch(entryFeeText);
      if (isNumeric && !entryFeeText.contains('₹')) {
        entryFeeText = '₹$entryFeeText';
      }
    }

    final items = [
      (
        Icons.calendar_month_rounded,
        DateFormat('dd MMM').format(event.date),
        'Date',
      ),
      (Icons.access_time_rounded, event.startTime, 'Time'),
      (Icons.currency_rupee_rounded, entryFeeText, 'Entry'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appGreyLight),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, size: 20, color: primaryBlue),
                      const SizedBox(height: 8),
                      AppText.small(
                        item.$2,
                        fontWeight: FontWeight.w600,
                        color: appBlack,
                        size: 13,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      AppText.caption(
                        item.$3,
                        color: appGrey,
                        size: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          appGreyLight.withAlpha(0),
                          appGreyLight,
                          appGreyLight.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        AppText.subHeading(title, fontWeight: FontWeight.w700, size: 18),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("About this Event"),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(
              event.description,
              color: appGreyDark,
              align: TextAlign.justify,
              size: 14,
              height: 1.6,
              maxLines: isDescriptionExpanded ? null : 6,
              overflow: isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (event.description.length > 200) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onDescriptionToggle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.body(
                      isDescriptionExpanded ? "Read Less" : "Read Full Story",
                      color: primaryBlue,
                      fontWeight: FontWeight.w800,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isDescriptionExpanded
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

  Widget _buildOrganizerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Organizer'),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _showContactBottomSheet(context, event),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appGreyLight),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryBlue.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: primaryBlue,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                              fontWeight: FontWeight.w700,
                              size: 17,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (event.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              color: primaryBlue,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppText.caption(
                        "Tap to contact host",
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: appGrey,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showContactBottomSheet(BuildContext context, EventModel event) {
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
                onTap: () => onLaunchUrl('tel:${event.contactNumber}'),
                color: Colors.green,
              ),
            if (event.website != null) ...[
              const SizedBox(height: 12),
              _bottomSheetAction(
                icon: Icons.public_rounded,
                title: "Official Website",
                subtitle: "Visit event page",
                onTap: () => onLaunchUrl(event.website!),
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
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(14),
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
                child: Icon(icon, color: color, size: 40),
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
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Location"),
        const SizedBox(height: 16),
        ExternalActionCard(
          title: event.venue,
          subtitle: event.address,
          icon: Icons.directions_rounded,
          onTap: () => onLaunchUrl(
            'https://www.google.com/maps/dir/?api=1&destination=${event.lat},${event.lng}',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final status = getEventStatus(event);
    final isEnded = status == "Event Ended";
    final isInterested = event.interestedUsers.contains(userId);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: appWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.caption(
                      isEnded ? "Status" : "Are you coming?",
                      color: appGrey,
                      fontWeight: FontWeight.w600,
                    ),
                    AppText.body(
                      isEnded ? "Event Ended" : "Join the fun!",
                      fontWeight: FontWeight.w800,
                      color: isEnded ? appGrey : appBlack,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              isInterestedLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: CircularProgressIndicator(color: primaryBlue),
                    )
                  : ElevatedButton(
                      onPressed: isEnded ? null : onToggleInterest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInterested
                            ? Colors.green
                            : primaryBlue,
                        foregroundColor: appWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInterested
                                ? Icons.check_circle_outline_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          AppText.button(
                            isInterested ? "ATTENDING" : "INTERESTED",
                            color: appWhite,
                            fontWeight: FontWeight.w900,
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
}
