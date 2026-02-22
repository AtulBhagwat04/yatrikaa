import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';

class ManagePlacesScreen extends StatefulWidget {
  const ManagePlacesScreen({super.key});

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  List<dynamic> _places = [];
  bool _isLoading = true;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/places/popular'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _places = data['results'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load places');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: appBlack,
            size: 20,
          ),
        ),
        title: AppText.subHeading(
          'Manage Places',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: primaryBlue,
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                RouteNames.addPlace,
              );
              if (result == true) _fetchPlaces();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.body('Error: $_error', color: Colors.red),
            TextButton(onPressed: _fetchPlaces, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_places.isEmpty) return const Center(child: Text('No places found'));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _getPhotoUrl(_getPlacePhotoReference(place)),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            title: AppText.body(
              place['name'] ?? 'Unknown',
              fontWeight: FontWeight.bold,
            ),
            subtitle: AppText.caption(
              place['address'] ?? 'No address',
              maxLines: 1,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
              onSelected: (val) {
                if (val == 'delete') {
                  _deletePlace(place['place_id']);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$val operation selected for ${place['name']}',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
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
