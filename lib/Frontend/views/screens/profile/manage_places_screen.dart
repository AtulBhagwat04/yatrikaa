import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/core/utils/error_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/core/services/places_service.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/views/widgets/shimmer_box.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_location_field.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_search_bar.dart';
import 'package:yatrikaa/Frontend/views/widgets/custom_alert_dialog.dart';

class ManagePlacesScreen extends StatefulWidget {
  const ManagePlacesScreen({super.key});

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  List<PlaceModel> _allPlaces = [];
  List<PlaceModel> _filteredPlaces = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final PlacesService _placesService = PlacesService();
  final ImagePicker _picker = ImagePicker();

  // Pagination & Scroll state
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _pageSize = 12;
  bool _hasMore = false;
  bool _isMoreLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isMoreLoading && _hasMore && !_isLoading) {
        _fetchPlaces(refresh: false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlaces({bool refresh = true, String? search}) async {
    if (!mounted) return;

    final currentSearch = search ?? _searchController.text.trim();

    setState(() {
      if (refresh) {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      } else {
        _isMoreLoading = true;
      }
    });

    try {
      final List<PlaceModel> places;
      final bool hasMore;

      if (currentSearch.isNotEmpty) {
        // Use the same search service as the suggestions for consistency
        places = await _placesService.searchPlaces(currentSearch);
        hasMore =
            false; // Search results from this endpoint are currently non-paginated
      } else {
        // Use regular paginated fetch for the default view
        final result = await _placesService.getPlacesPaginated(
          page: refresh ? 1 : _currentPage + 1,
          limit: _pageSize,
        );
        places = result['places'] ?? [];
        hasMore = result['hasMore'] ?? false;
      }

      if (!mounted) return;

      // 🚨 CRITICAL: Check if search query has changed since we started.
      final latestSearchCheck = _searchController.text.trim();
      if (currentSearch != latestSearchCheck) return;

      setState(() {
        if (refresh) {
          _allPlaces = places;
          _currentPage = 1;
        } else {
          _allPlaces.addAll(places);
          if (currentSearch.isEmpty) _currentPage++;
        }
        _hasMore = hasMore;

        // Re-apply filter
        final query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          _filteredPlaces = _allPlaces.where((place) {
            final name = (place.name ?? '').toLowerCase();
            final address = (place.formattedAddress ?? '').toLowerCase();
            return name.contains(query) || address.contains(query);
          }).toList();
        } else {
          _filteredPlaces = _allPlaces;
        }

        _isLoading = false;
        _isMoreLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      print('[ManagePlaces] Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isMoreLoading = false;
      });
    }
  }

  void _filterPlaces(String query) {
    if (!mounted) return;
    final lowQuery = query.toLowerCase().trim();
    setState(() {
      if (lowQuery.isEmpty) {
        _filteredPlaces = _allPlaces;
      } else {
        _filteredPlaces = _allPlaces.where((place) {
          final name = (place.name ?? '').toLowerCase();
          final address = (place.formattedAddress ?? '').toLowerCase();
          return name.contains(lowQuery) || address.contains(lowQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetchPlaces,
          displacement:
              80, // Moves the pull-to-refresh spinner below the AppBar
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
            RouteNames.addPlace,
          );
          if (result == true) _fetchPlaces();
        },
        backgroundColor: primaryBlue,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: 'Add New Place',
        child: const Icon(
          Icons.add_location_alt_rounded,
          color: Colors.white,
          size: 28,
        ),
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
        "Manage Places",
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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ModernSearchBar(
            controller: _searchController,
            onChanged: (val) {
              _debounceTimer?.cancel();
              // 1. Immediate local filter for responsiveness
              _filterPlaces(val);

              // 2. Debounced server-side search for accuracy
              _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                if (val.trim().isNotEmpty) {
                  _fetchPlaces(refresh: true, search: val.trim());
                } else {
                  _fetchPlaces(refresh: true); // Reset to full list
                }
              });
            },
            suggestionsEnabled: false,
            hint: "Search your places...",
            icon: Icons.search_rounded,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    // Show loading indicator if we are searching (and have no filtered items yet)
    if (_isLoading && _filteredPlaces.isEmpty) {
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
              AppText.body("Error loading places", fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _fetchPlaces,
                child: const Text("Retry Now"),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredPlaces.isEmpty && !_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchController.text.isEmpty
                    ? Icons.location_off_rounded
                    : Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              AppText.body(
                _searchController.text.isEmpty
                    ? "No places found"
                    : "No results matching \"${_searchController.text.trim()}\"",
                color: Colors.grey,
              ),
              if (_hasMore || _searchController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _fetchPlaces(refresh: false),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _searchController.text.isEmpty
                        ? "Load More"
                        : "Search On Server",
                  ),
                  style: TextButton.styleFrom(foregroundColor: primaryBlue),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final place = _filteredPlaces[index];
          return _buildPlaceCard(place);
        }, childCount: _filteredPlaces.length),
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

  Widget _buildPlaceCard(PlaceModel place) {
    final photoRef = _getPlacePhotoReference(place);
    final category = (place.types != null && place.types!.isNotEmpty)
        ? place.types!.first
        : 'Place';

    return Container(
      key: ValueKey(place.id ?? place.name),
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
                Image.network(
                  _getPhotoUrl(photoRef),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          AppText.small(
                            "No Preview",
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
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
                        onTap: () => _editPlace(place),
                        tooltip: 'Edit Place',
                      ),
                      const SizedBox(width: 8),
                      _buildCircularButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        isDestructive: true,
                        onTap: () => _confirmDelete(place),
                        tooltip: 'Delete Place',
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: AppText.small(
                      category.toString().toUpperCase(),
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
                          place.name ?? 'Unknown Place',
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
                                place.formattedAddress ??
                                    'No address available',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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

  void _editPlace(PlaceModel place) {
    final nameController = TextEditingController(text: place.name);
    final addressController = TextEditingController(
      text: place.formattedAddress,
    );
    final descriptionController = TextEditingController(
      text: place.description ?? '',
    );

    List<String> currentUrls = List.from(place.images);

    List<XFile> pickedFiles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSheetLoading = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            List<Map<String, dynamic>> combinedItems = [
              ...currentUrls.map(
                (p) => {'url': _getPhotoUrl(p), 'type': 'image', 'data': p},
              ),
            ];
            List<String> displayUrls = combinedItems
                .map((item) => item['url'] as String)
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.heading(
                          "Edit Place Gallery",
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
                                ...displayUrls.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  String url = entry.value;
                                  return Container(
                                    width: 130,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                              if (combinedItems.length == 1 &&
                                                  pickedFiles.isEmpty) {
                                                CustomToast.warning(
                                                  context,
                                                  "At least one image is required",
                                                  title: "Wait!",
                                                );
                                                return;
                                              }
                                              setSheetState(() {
                                                currentUrls.remove(
                                                  combinedItems[idx]['data'],
                                                );
                                                combinedItems = [
                                                  ...currentUrls.map(
                                                    (p) => {
                                                      'url': _getPhotoUrl(p),
                                                      'type': 'image',
                                                      'data': p,
                                                    },
                                                  ),
                                                ];
                                                displayUrls = combinedItems
                                                    .map(
                                                      (item) =>
                                                          item['url'] as String,
                                                    )
                                                    .toList();
                                              });
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
                                for (var i = 0; i < pickedFiles.length; i++)
                                  Container(
                                    width: 130,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            File(pickedFiles[i].path),
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
                                              () => pickedFiles.removeAt(i),
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
                                  ),
                                GestureDetector(
                                  onTap: () async {
                                    if (combinedItems.length +
                                            pickedFiles.length >=
                                        10) {
                                      CustomToast.warning(
                                        context,
                                        "Maximum 10 images allowed",
                                        title: "Hold on!",
                                      );
                                      return;
                                    }
                                    final imgs = await _picker.pickMultiImage();
                                    if (imgs.isNotEmpty) {
                                      setSheetState(
                                        () => pickedFiles.addAll(
                                          imgs.take(
                                            10 -
                                                (combinedItems.length +
                                                    pickedFiles.length),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 130,
                                    decoration: BoxDecoration(
                                      color: onboardingBlueVeryLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        style: BorderStyle.solid,
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
                            "PLACE INFO",
                            size: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 16),
                          _buildSheetField(
                            "Place Name",
                            nameController,
                            Icons.place_rounded,
                          ),
                          const SizedBox(height: 16),
                          ModernLocationField(
                            controller: addressController,
                            label: "Address",
                            hint: "Search and select address",
                          ),
                          const SizedBox(height: 16),
                          _buildSheetField(
                            "Description",
                            descriptionController,
                            Icons.notes_rounded,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isSheetLoading
                                  ? () {}
                                  : () async {
                                      if (currentUrls.isEmpty &&
                                          pickedFiles.isEmpty) {
                                        CustomToast.warning(
                                          context,
                                          "At least one image is required",
                                          title: "Wait!",
                                        );
                                        return;
                                      }

                                      setSheetState(
                                        () => isSheetLoading = true,
                                      );
                                      final success = await _handleUpdate(
                                        place.id!,
                                        {
                                          'place_id': place.id,
                                          'name': nameController.text.trim(),
                                          'description': descriptionController
                                              .text
                                              .trim(),
                                          'editorial_summary': {
                                            'overview': descriptionController
                                                .text
                                                .trim(),
                                          },
                                          'formatted_address': addressController
                                              .text
                                              .trim(),
                                          'address': addressController.text
                                              .trim(),
                                          'category': place.category,
                                          'types': place.types,
                                          'images': currentUrls,
                                          // Only send photos as references if they aren't already full URLs
                                          'photos': currentUrls
                                              .where(
                                                (p) => !p.startsWith('http'),
                                              )
                                              .map(
                                                (p) => {'photo_reference': p},
                                              )
                                              .toList(),
                                        },
                                        pickedFiles,
                                      );

                                      if (success && mounted) {
                                        Navigator.pop(ctx);
                                      } else if (mounted) {
                                        setSheetState(
                                          () => isSheetLoading = false,
                                        );
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
                                  : AppText.body(
                                      "Update Place Info",
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(label.toUpperCase(), size: 12, color: Colors.grey),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryBlue, size: 20),
            filled: true,
            fillColor: onboardingBlueVeryLight.withOpacity(0.5),
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
    );
  }

  Future<bool> _handleUpdate(
    String id,
    Map<String, dynamic> body,
    List<XFile> images,
  ) async {
    try {
      final success = await _placesService.updatePlace(
        id,
        body,
        imageFiles: images,
      );
      if (success && mounted) {
        CustomToast.success(context, "Place updated successfully!");
        _refreshSinglePlace(id);
        return true;
      }

      if (mounted) {
        CustomToast.error(context, "Failed to update place. Please try again.");
      }
      return false;
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
      return false;
    }
  }

  void _confirmDelete(PlaceModel place) {
    CustomAlertDialog.show(
      context,
      title: 'Delete Place?',
      message:
          "Are you sure you want to remove '${place.name}'? This action cannot be undone.",
      confirmLabel: 'Delete',
      type: CustomAlertType.error,
      icon: Icons.delete_forever_rounded,
      onConfirm: () => _deletePlace(place.id),
    );
  }

  String _getPlacePhotoReference(PlaceModel place) {
    if (place.images.isNotEmpty) {
      return place.images[0];
    }
    return '';
  }

  String _getPhotoUrl(String photoReference) {
    if (photoReference.isEmpty) return '';
    return ApiConstants.getPhotoUrl(photoReference);
  }

  Future<void> _deletePlace(String placeId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/places/$placeId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          CustomToast.success(context, 'Place deleted successfully');
        }
        setState(() {
          _allPlaces.removeWhere((p) => p.id == placeId);
          _filterPlaces(_searchController.text);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to delete place');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshSinglePlace(String id) async {
    try {
      final updatedPlace = await _placesService.getPlaceDetails(id);
      if (!mounted) return;

      setState(() {
        final index = _allPlaces.indexWhere((p) => p.id == id);
        if (index != -1) {
          _allPlaces[index] = updatedPlace;
        }
        _filterPlaces(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      print('[ManagePlaces] Error refreshing single place: $e');
      // Fallback to full refresh if single fetch fails
      _fetchPlaces();
    }
  }
}
