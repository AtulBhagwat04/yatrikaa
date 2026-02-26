import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';

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
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: appBlack,
          size: 20,
        ),
      ),
      title: AppText.heading(
        "Manage Places",
        size: 22,
        fontWeight: FontWeight.w900,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _fetchPlaces,
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
            onChanged: _filterPlaces,
            decoration: InputDecoration(
              hintText: "Search your places...",
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
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${place['rating'] ?? '4.5'}",
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
                  const SizedBox(width: 8),
                  _buildActionMenu(place),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(dynamic place) {
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
              AppText.body("Edit Details"),
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
              AppText.body("Delete Place", color: Colors.redAccent),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'delete') {
          _confirmDelete(place);
        }
      },
    );
  }

  void _confirmDelete(dynamic place) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: AppText.subHeading("Delete Place?"),
        content: AppText.body(
          "Are you sure you want to remove '${place['name']}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePlace(place['place_id']);
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

  String _getPlacePhotoReference(dynamic place) {
    if (place['photos'] != null &&
        place['photos'] is List &&
        place['photos'].isNotEmpty) {
      return place['photos'][0]['photo_reference'] ?? '';
    }
    return '';
  }

  String _getPhotoUrl(String photoReference) {
    if (photoReference.isEmpty) return '';
    return '${ApiConstants.baseUrl}/places/photo/$photoReference';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Place deleted successfully')),
          );
        }
        _fetchPlaces();
      } else {
        throw Exception('Failed to delete place');
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
