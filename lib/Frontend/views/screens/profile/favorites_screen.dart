import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/core/services/places_service.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_event.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';

class FavoritesScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onGoExplore;

  const FavoritesScreen({
    super.key,
    this.showBackButton = true,
    this.onGoExplore,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final PlacesService _placesService = PlacesService();
  List<PlaceModel> _likedPlaces = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLikedPlaces();
  }

  Future<void> _fetchLikedPlaces() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final places = await _placesService.getFavoritePlaces();

      if (!mounted) return;

      setState(() {
        _likedPlaces = places;
        _isLoading = false;
      });

      // Sync global count with reality
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<AuthBloc>().add(SyncAuthCounts());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: AppText.heading(
          'Liked Places',
          fontWeight: FontWeight.w900,
          size: 20,
        ),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) {
          if (prev is Authenticated && curr is Authenticated) {
            return prev.savedCount != curr.savedCount;
          }
          return false;
        },
        listener: (context, state) {
          _fetchLikedPlaces();
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _fetchLikedPlaces,
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                AppText.body(
                  "Error loading favorites",
                  fontWeight: FontWeight.bold,
                ),
                TextButton(
                  onPressed: _fetchLikedPlaces,
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_likedPlaces.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLikedPlaces,
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: _buildEmptyUI(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLikedPlaces,
      color: primaryBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _likedPlaces.length,
        itemBuilder: (context, index) {
          final place = _likedPlaces[index];
          return _buildPlaceCard(place);
        },
      ),
    );
  }

  Widget _buildPlaceCard(PlaceModel place) {
    return Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.pushNamed(
                context,
                RouteNames.placeDetails,
                arguments: {'placeId': place.id, 'place': place},
              );
              _fetchLikedPlaces();
            },
            child: Column(
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: place.photoUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ShimmerBox(height: 180),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
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
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${place.rating}",
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
                          place.category?.toUpperCase() ?? "PLACE",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          size: 10,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 12,
                      left: 12,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 28,
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
                              place.name,
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
                                    place.address ?? 'No address available',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
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

  Widget _buildEmptyUI() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          AppText.heading(
            'No Liked Places',
            size: 22,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(height: 12),
          AppText.body(
            'Explore amazing destinations and save your favorites to plan your next adventure!',
            align: TextAlign.center,
            color: Colors.grey.shade500,
            size: 14,
          ),
          const SizedBox(height: 40),
          _buildExploreButton(),
        ],
      ),
    );
  }

  Widget _buildExploreButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (widget.onGoExplore != null) {
            widget.onGoExplore!();
          } else if (widget.showBackButton) {
            Navigator.maybePop(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryBlue.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Go Explore',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
