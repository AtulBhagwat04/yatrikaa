import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import '../../../core/constants/app_text.dart';
import '../../../core/constants/text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;

  String currentLocation = "Fetching location...";
  bool isLoadingLocation = true;

  final List<String> categories = [
    "Forts",
    "Beaches",
    "Temples",
    "Trekking",
    "Hill Stations"
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    if (hour < 20) return "Good Evening";
    return "Good Night";
  }

  // ================= LOCATION =================

  Future<void> _initLocation() async {
    try {
      setState(() => isLoadingLocation = true);

      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          currentLocation = "Turn on GPS";
          isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          currentLocation = "Location permission needed";
          isLoadingLocation = false;
        });
        return;
      }

      Position position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      try {
        List<Placemark> placemarks =
        await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        Placemark place = placemarks.first;

        setState(() {
          currentLocation =
          "${place.locality ?? ""}, ${place.administrativeArea ?? ""}";
          isLoadingLocation = false;
        });
      } catch (_) {
        setState(() {
          currentLocation =
          "${position.latitude}, ${position.longitude}";
          isLoadingLocation = false;
        });
      }
    } catch (_) {
      setState(() {
        currentLocation = "Location unavailable";
        isLoadingLocation = false;
      });
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.ms),
          children: [

            /// Greeting + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      AppText.subHeading(
                        _getGreeting(),
                        align: TextAlign.left,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      AppText.caption(
                        "Ready for your next Journey?",
                        align: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                _notificationButton(),
                SizedBox(width: AppSpacing.s),
                _profileButton(),
              ],
            ),

            SizedBox(height: AppSpacing.m),

            _buildLocationCard(),

            SizedBox(height: AppSpacing.m),

            _buildCategories(),

            SizedBox(height: AppSpacing.m),

            _buildSectionTitle("Recommended"),
            SizedBox(height: AppSpacing.m),
            _buildHorizontalCards(),

            SizedBox(height: AppSpacing.l),

            _buildSectionTitle("Nearby Places"),
            SizedBox(height: AppSpacing.m),
            _buildNearbyCard(),

            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================= TOP BUTTONS =================

  Widget _notificationButton() {
    bool hasNotification = true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: primaryBlue,
                size: 22,
              ),
            ),
            if (hasNotification)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.2),
            ),
          ),
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: primaryWhite,
            child: Icon(
              Icons.person,
              color: primaryBlue,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ================= LOCATION CARD =================

  Widget _buildLocationCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: primaryWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: primaryBlue,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                AppText.caption(
                  "Current Location",
                  align: TextAlign.left,
                ),
                SizedBox(height: AppSpacing.xs),
                AppText.body(
                  isLoadingLocation
                      ? "Detecting..."
                      : currentLocation,
                  align: TextAlign.left,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(
          title,
          align: TextAlign.left,
          fontWeight: FontWeight.w700,
        ),
        AppText.caption(
          "View All",
          color: primaryBlue,
        ),
      ],
    );
  }

  // ================= HORIZONTAL CARDS =================

  Widget _buildHorizontalCards() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 230,
            margin: EdgeInsets.only(right: AppSpacing.s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image:
                AssetImage("assets/images/sample.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              alignment: Alignment.bottomCenter,
              child: AppText.body(
                "Rajgad Fort",
                color: appWhite,
                align: TextAlign.left,
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= NEARBY CARD =================

  Widget _buildNearbyCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: primaryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image:
                AssetImage("assets/images/sample.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                AppText.body(
                  "Sinhagad Fort",
                  align: TextAlign.left,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: AppSpacing.xs),
                AppText.caption(
                  "2.5 km away",
                  align: TextAlign.left,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= BOTTOM NAV =================

  Widget _buildBottomNav() {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: primaryWhite,
        borderRadius:
        const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home),
          _navItem(1, Icons.near_me_rounded),
          _navItem(2, Icons.search_rounded),
          _navItem(3, Icons.favorite_rounded),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
            const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? primaryBlue
                      : Colors.grey,
                ),
                AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 200),
                  height: 3,
                  width: isSelected ? 22 : 0,
                  margin:
                  const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected =
              _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: AppSpacing.s),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: primaryWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? primaryBlue
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: AppText.caption(
                categories[index],
                color: isSelected
                    ? primaryBlue
                    : Colors.black87,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

}
