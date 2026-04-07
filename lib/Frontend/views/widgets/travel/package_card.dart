import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';

class PackageCard extends StatefulWidget {
  final TravelPackageModel package;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double radius;

  const PackageCard({
    super.key,
    required this.package,
    required this.onTap,
    this.width = 280,
    this.height = 210,
    this.radius = 14,
  });

  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  late List<String> _displayMessages;

  @override
  void initState() {
    super.initState();
    _displayMessages = _getAttractiveMessages();
    _startMessageCycle();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startMessageCycle() {
    if (_displayMessages.length > 1) {
      _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          setState(() {
            _currentMessageIndex =
                (_currentMessageIndex + 1) % _displayMessages.length;
          });
        }
      });
    }
  }

  List<String> _getAttractiveMessages() {
    final category = widget.package.category.toLowerCase();
    
    // Category-specific message pools (10 each)
    final Map<String, List<String>> categoryPools = {
      "adventure": [
        "Thrilling Fort Treks",
        "Peak Summit Guaranteed",
        "Safety Gear Provided",
        "Pro Trekking Guides",
        "High Altitude Fun",
        "Camping Under Stars",
        "Adrenaline Guaranteed",
        "Tough but Rewarding",
        "Meet Fellow Trekkers",
        "Action Packed Itinerary",
      ],
      "religious": [
        "Peaceful Temple Tour",
        "Spiritual Awakening",
        "Divine Darshan Access",
        "Pooja Arrangements Done",
        "Blessings of God",
        "Soul Soothing Journey",
        "Pure Vegetarian Meals",
        "Calm & Sacred Vibes",
        "Historical Holy Sites",
        "Spiritual Group Walk",
      ],
      "nature": [
        "Breath of Fresh Air",
        "Panoramic Valley Views",
        "Waterfall Exploration",
        "Mist & Mountains",
        "Floral Beauty Covered",
        "Sunset Point Special",
        "Serene Forest Trails",
        "Nature Photography",
        "Eco-Friendly Travel",
        "Chill & Relax Vibes",
      ],
      "beach": [
        "Sand & Sun Fun",
        "Pristine Blue Waters",
        "Authentic Sea Food",
        "Sunset Beach Walk",
        "Water Sports Included",
        "Coastal Village Stay",
        "Beachside Bonfire",
        "Fresh Coconut Water",
        "Tropical Paradise",
        "Island Hopping Fun",
      ],
      "heritage": [
        "Echoes of History",
        "Ancient Cave Wonders",
        "Architectural Marvels",
        "Guided Museum Tours",
        "History & Myths",
        "Storytelling Sessions",
        "Cultural Preservation",
        "Vintage Vibe Stays",
        "Walk Through Time",
        "Kingdom's Legacy",
      ],
      "family": [
        "Safe for Seniors",
        "Kid Friendly Resorts",
        "Stress Free Planning",
        "Comfort First Travel",
        "Group Activity Fun",
        "Buffet Breakfasts",
        "Spacious Luxury Stay",
        "Create Family Bonds",
        "Easy Pace Discovery",
        "Home Away From Home",
      ],
    };

    // Generic fallback pool
    final List<String> fallbackPool = [
      "Limited Time Offer! 🔥",
      "Includes Guided Tour",
      "Most Loved Package ❤️",
      "Unforgettable Memories",
      "Special Group Discount",
      "Explore the Unexplored",
      "Breakfast & Dinner Included",
      "Premium Stay Guaranteed",
      "Best for Solo Travelers",
      "Perfect Weekend Getaway",
    ];

    // Select the appropriate pool based on category
    List<String> activePool = fallbackPool;
    for (var key in categoryPools.keys) {
      if (category.contains(key)) {
        activePool = categoryPools[key]!;
        break;
      }
    }

    final seed = widget.package.id.hashCode.abs();
    final List<String> selected = [];

    // 1. Add Priority State if applicable (Always keep these as first priority)
    if (widget.package.isPopular) selected.add("Trending Now 🔥");
    if (widget.package.averageRating >= 4.8) selected.add("Top Rated Choice ✨");
    if (widget.package.maxGroupSize - widget.package.currentParticipants < 4) {
      selected.add("Last Few Slots!");
    }

    // 2. Fill with messages from the specific category pool
    int offset = 0;
    while (selected.length < 3) {
      final msg = activePool[(seed + offset) % activePool.length];
      if (!selected.contains(msg)) {
        selected.add(msg);
      }
      offset++;
    }

    return selected.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 25,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: widget.package.mainPhotoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerBox(),
                errorWidget: (context, url, error) => Container(
                  color: appGreyVeryLight,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: appGrey,
                  ),
                ),
              ),

              // Gradient Depth
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Glassmorphic Duration Tag
              Positioned(
                top: 12,
                right: 12,
                child: _buildGlassBadge(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.package.days}D / ${widget.package.nights}N",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.package.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Animated Message Section
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  widget.package.isPopular
                                      ? Icons.auto_awesome_rounded
                                      : Icons.local_offer_rounded,
                                  color: widget.package.isPopular
                                      ? Colors.amber
                                      : Colors.white.withOpacity(0.7),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 600),
                                      layoutBuilder: (Widget? currentChild,
                                          List<Widget> previousChildren) {
                                        return Stack(
                                          alignment: Alignment.centerLeft,
                                          children: <Widget>[
                                            ...previousChildren,
                                            if (currentChild != null)
                                              currentChild,
                                          ],
                                        );
                                      },
                                      transitionBuilder: (
                                        Widget child,
                                        Animation<double> animation,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.0, 0.5),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        _displayMessages[_currentMessageIndex],
                                        key: ValueKey(
                                          _displayMessages[_currentMessageIndex],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: widget.package.isPopular
                                              ? Colors.amber
                                              : Colors.white.withOpacity(0.7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // CTA Button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              "JOIN NOW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
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

  Widget _buildGlassBadge({required Widget child, Color? backgroundColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
