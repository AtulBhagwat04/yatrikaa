import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/place_model.dart';
import '../constants/api_constants.dart';
import '../constants/app_strings.dart';
import 'auth_service.dart';
import '../utils/app_cache.dart';
import 'package:yatrikaa/Frontend/core/services/backend_health_manager.dart';

class PlacesService {
  final AuthService _authService = AuthService();

  /// Fetches popular places from DB. This is a legacy method.
  Future<List<PlaceModel>> getFamousMaharashtraPlaces({
    String? category,
    int page = 1,
    int limit = 12,
  }) async {
    final result = await getPlacesPaginated(category: category, page: page, limit: limit);
    return result['places'] as List<PlaceModel>;
  }

  /// Modern paginated fetch returning a Map with 'places', 'hasMore', and 'totalCount'
  Future<Map<String, dynamic>> getPlacesPaginated({
    String? category,
    int page = 1,
    int limit = 12,
  }) async {
    try {
      String url = ApiConstants.getPopularPlacesUrl(page: page, limit: limit);
      if (category != null && category != AppStrings.catAll) {
        url += "&category=${Uri.encodeComponent(category)}";
      }

      final response = await BackendHealthManager.instance.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List results = data['results'] ?? [];
        bool hasMoreFromBackend = data['hasMore'] ?? false;

        // ── Client-side Slicing Fallback ────────────────────────────────────
        if (data['hasMore'] == null && results.length > limit) {
          final int start = (page - 1) * limit;
          final int end = start + limit;
          final List fullList = List.from(results);
          
          if (start < fullList.length) {
            results = fullList.sublist(
              start,
              end < fullList.length ? end : fullList.length,
            );
            hasMoreFromBackend = end < fullList.length;
          } else {
            results = [];
            hasMoreFromBackend = false;
          }
        }

        // Save to cache for offline support (only first page, all-category)
        if (page == 1 && (category == null || category == AppStrings.catAll)) {
          await AppCache.saveRawData(AppCache.keyExplore, results);
          await AppCache.saveRawData(AppCache.keyRecommended, results);
        }

        List<PlaceModel> places = results
            .map((json) => PlaceModel.fromJson(json))
            .toList();

        // Shuffle only the first page so the home preview varies
        if (page == 1) places.shuffle();

        return {
          'places': places,
          'hasMore': hasMoreFromBackend,
          'totalCount': data['totalCount'] ?? results.length,
        };
      } else {
        throw Exception("Failed to fetch popular places from DB: ${response.statusCode}");
      }
    } catch (e) {
      print('[PlacesService] Error fetching paginated places: $e');

      // Fall back to cache on first page only
      if (page == 1 && (category == null || category == AppStrings.catAll)) {
        final cachedData = await AppCache.getRawData(AppCache.keyExplore);
        if (cachedData.isNotEmpty) {
          final places = cachedData
              .map((json) => PlaceModel.fromJson(json))
              .toList();
          places.shuffle();
          return {
            'places': places,
            'hasMore': false,
            'totalCount': places.length,
          };
        }
      }

      return {'places': <PlaceModel>[], 'hasMore': false, 'totalCount': 0};
    }
  }

  Future<List<PlaceModel>> getNearbyPlaces(double lat, double lng) async {
    try {
      final response = await BackendHealthManager.instance.get(
        ApiConstants.getSearchPlacesUrl(
          AppStrings.pdDiscoveryQuery,
          lat: lat,
          lng: lng,
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        List<PlaceModel> places = results
            .map((json) => PlaceModel.fromJson(json))
            .toList();
        return places;
      } else {
        throw Exception("Failed to fetch nearby places");
      }
    } catch (e) {
      print('Error fetching nearby places from API: $e');
      return [];
    }
  }

  Future<List<PlaceModel>> searchPlaces(String query, {double? lat, double? lng}) async {
    try {
      final response = await BackendHealthManager.instance.get(
        ApiConstants.getSearchPlacesUrl(query, lat: lat, lng: lng),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => PlaceModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to search places");
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  Future<PlaceModel> getPlaceDetails(String id) async {
    final response = await BackendHealthManager.instance.get(
      ApiConstants.getPlaceDetailsUrl(id),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PlaceModel.fromJson(data['result']);
    } else {
      throw Exception("Failed to fetch place details");
    }
  }

  Future<bool> checkIfFavorite(String placeId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/places/favorites/check/$placeId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  Future<bool> updatePlace(String id, Map<String, dynamic> body, {List<XFile>? imageFiles}) async {
    return editPlace(id, body, imageFiles: imageFiles);
  }

  Future<bool> editPlace(String id, Map<String, dynamic> body, {List<XFile>? imageFiles}) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/places/$id');
      var request = http.MultipartRequest('PUT', uri);
      
      request.headers['Authorization'] = 'Bearer $token';

      // Attach fields
      body.forEach((key, value) {
        if (value is Map || value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      // Attach new images
      if (imageFiles != null) {
        for (var image in imageFiles) {
          request.files.add(await http.MultipartFile.fromPath(
            'images',
            image.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      print('Error editing place: $e');
      return false;
    }
  }

  Future<bool> addPlace(Map<String, dynamic> body, {List<XFile>? imageFiles}) async {
    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/places');
      var request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';

      // Attach fields
      body.forEach((key, value) {
        if (value is Map || value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      // Attach images
      if (imageFiles != null) {
        for (var image in imageFiles) {
          request.files.add(await http.MultipartFile.fromPath(
            'images',
            image.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Add place error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding place: $e');
      return false;
    }
  }

  Future<bool> deletePlace(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/places/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting place: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String placeId, {PlaceModel? place}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/places/toggle-favorite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'placeId': placeId,
          if (place != null) 'placeData': place.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to toggle favorite");
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return {'error': e.toString()};
    }
  }

  Future<List<PlaceModel>> getFavoritePlaces() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/places/favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => PlaceModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to fetch favorite places");
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  Future<PlaceModel?> addReview(String placeId, double rating, String text) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/places/$placeId/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PlaceModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error adding review to place: $e');
      return null;
    }
  }

  Future<PlaceModel?> updateReview(String placeId, String reviewId, double rating, String text) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/places/$placeId/reviews/$reviewId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlaceModel.fromJson(data['result']);
      }
      return null;
    } catch (e) {
      print('Error updating review: $e');
      return null;
    }
  }

  Future<PlaceModel?> deleteReview(String placeId, String reviewId) async {
    try {
      final token = await _authService.getToken();
      final url = '${ApiConstants.baseUrl}/places/$placeId/reviews/$reviewId';
      print('[PlacesService] DELETE Review URL: $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlaceModel.fromJson(data['result']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete review');
      }
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }
}

