import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bhatkanti_app/Frontend/core/utils/error_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';
import 'package:bhatkanti_app/Frontend/core/services/places_service.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/shimmer_box.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/custom_alert_dialog.dart';

class ManagePlacesScreen extends StatefulWidget {
  const ManagePlacesScreen({super.key});

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  List<dynamic> _allPlaces = [];
  List<dynamic> _filteredPlaces = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final PlacesService _placesService = PlacesService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlaces() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/places/popular'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allPlaces = data['results'] ?? [];
          _filteredPlaces = _allPlaces;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load places');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterPlaces(String query) {
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final name = (place['name'] ?? '').toLowerCase();
        final address = (place['formatted_address'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            address.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: RefreshIndicator(
        onRefresh: _fetchPlaces,
        displacement: 80, // Moves the pull-to-refresh spinner below the AppBar
        color: primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(),
            _buildSearchBox(),
            _buildList(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
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
      automaticallyImplyLeading: false,
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
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterPlaces,
            decoration: InputDecoration(
              hintText: "Search your places...",
              hintStyle: GoogleFonts.montserrat(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
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
    // Only show full-screen loader if list is absolutely empty and we are loading
    if (_isLoading && _allPlaces.isEmpty) {
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

    if (_filteredPlaces.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              AppText.body("No places found", color: Colors.grey),
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

  Widget _buildPlaceCard(dynamic place) {
    final photoRef = _getPlacePhotoReference(place);
    final categoryList = place['types'] as List?;
    final category = (categoryList != null && categoryList.isNotEmpty)
        ? categoryList.first
        : 'Place';

    return Container(
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
                  errorBuilder: (_, __, ___) => Container(
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
                          color: Colors.black.withOpacity(0.2),
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
                          place['name'] ?? 'Unknown Place',
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
                                place['formatted_address'] ??
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
            color: isDestructive ? Colors.white : Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
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

  void _editPlace(dynamic place) {
    final nameController = TextEditingController(text: place['name']);
    final addressController = TextEditingController(
      text: place['formatted_address'],
    );
    final descriptionController = TextEditingController(
      text:
          place['editorial_summary']?['overview'] ?? place['description'] ?? '',
    );

    // Manage list of existing photos/images
    List<dynamic> existingPhotos = List.from(place['photos'] ?? []);
    List<String> existingImages = List.from(
      (place['images'] as List?)?.map((e) => e.toString()) ?? [],
    );

    // Tracking locally
    // Tracking locally
    List<XFile> pickedFiles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Correctly combine ALL available images for a unified gallery experience
          List<Map<String, dynamic>> combinedItems = [
            ...existingPhotos.map(
              (p) => {
                'url': _getPhotoUrl(p['photo_reference'] ?? ''),
                'type': 'photo',
                'data': p,
              },
            ),
            ...existingImages.map(
              (url) => {'url': url, 'type': 'image', 'data': url},
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
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.heading(
                        "Edit Gallery",
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.subHeading(
                          "MANAGE GALLERY",
                          size: 12,
                          color: Colors.grey,
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
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: url,
                                          height: 150,
                                          width: 130,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              const ShimmerBox(),
                                          errorWidget: (_, __, ___) =>
                                              Container(
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
                                              var item = combinedItems[idx];
                                              if (item['type'] == 'photo') {
                                                existingPhotos.remove(
                                                  item['data'],
                                                );
                                              } else {
                                                existingImages.remove(
                                                  item['data'],
                                                );
                                              }
                                              // Re-sync local variables for UI rebuild
                                              combinedItems = [
                                                ...existingPhotos.map(
                                                  (p) => {
                                                    'url': _getPhotoUrl(
                                                      p['photo_reference'] ??
                                                          '',
                                                    ),
                                                    'type': 'photo',
                                                    'data': p,
                                                  },
                                                ),
                                                ...existingImages.map(
                                                  (url) => {
                                                    'url': url,
                                                    'type': 'image',
                                                    'data': url,
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
                                        borderRadius: BorderRadius.circular(12),
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
                                  final imgs = await _picker.pickMultiImage();
                                  if (imgs.isNotEmpty) {
                                    setSheetState(
                                      () => pickedFiles.addAll(imgs),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: onboardingBlueVeryLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: primaryBlue.withOpacity(0.3),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                        _buildSheetField(
                          "Place Name",
                          nameController,
                          Icons.place_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildSheetField(
                          "Address",
                          addressController,
                          Icons.map_rounded,
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
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (existingImages.isEmpty &&
                                  existingPhotos.isEmpty &&
                                  pickedFiles.isEmpty) {
                                CustomToast.warning(
                                  context,
                                  "At least one image is required",
                                  title: "Wait!",
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              _handleUpdate(place['place_id'], {
                                'name': nameController.text.trim(),
                                'description': descriptionController.text
                                    .trim(),
                                'formatted_address': addressController.text
                                    .trim(),
                                'photos': existingPhotos,
                                'images': existingImages,
                              }, pickedFiles);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: AppText.body(
                              "Update Place Info",
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

  Future<void> _handleUpdate(
    String id,
    Map<String, dynamic> body,
    List<XFile> images,
  ) async {
    setState(() => _isLoading = true);
    try {
      final success = await _placesService.updatePlace(
        id,
        body,
        imageFiles: images,
      );
      if (success && mounted) {
        CustomToast.success(context, "Place updated successfully!");
        _fetchPlaces();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete(dynamic place) {
    CustomAlertDialog.show(
      context,
      title: 'Delete Place?',
      message:
          "Are you sure you want to remove '${place['name']}'? This action cannot be undone.",
      confirmLabel: 'Delete',
      type: CustomAlertType.error,
      icon: Icons.delete_forever_rounded,
      onConfirm: () => _deletePlace(place['place_id']),
    );
  }

  String _getPlacePhotoReference(dynamic place) {
    if (place['photos'] != null &&
        place['photos'] is List &&
        place['photos'].isNotEmpty) {
      return place['photos'][0]['photo_reference'] ?? '';
    }
    if (place['images'] != null &&
        place['images'] is List &&
        place['images'].isNotEmpty) {
      return place['images'][0] ?? '';
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
        _fetchPlaces();
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
}
