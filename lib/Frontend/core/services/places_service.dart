import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../constants/api_constants.dart';
import '../constants/app_strings.dart';
import 'auth_service.dart';

class PlacesService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<PlaceModel>> getFamousMaharashtraPlaces({
    String? category,
  }) async {
    try {
      String url = ApiConstants.getPopularPlacesUrl();
      if (category != null && category != AppStrings.catAll) {
        url += "?category=${Uri.encodeComponent(category)}";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        List<PlaceModel> places = results
            .map((json) => PlaceModel.fromJson(json))
            .toList();

        // SHUFFLE the results so the order is different on every refresh
        places.shuffle();

        return places;
      } else {
        throw Exception("Failed to fetch popular places from DB");
      }
    } catch (e) {
      print('Error fetching popular places from DB: $e');
      return [];
    }
  }

  Future<List<PlaceModel>> getNearbyPlaces(double lat, double lng) async {
    try {
      // Use textSearch for better discovery of "Famous" places over a large 50km radius
      // as nearbySearch is often limited to smaller clusters.
      final response = await http.get(
        Uri.parse(
          ApiConstants.getSearchPlacesUrl(
            AppStrings.pdDiscoveryQuery,
            lat: lat,
            lng: lng,
          ),
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        List<PlaceModel> places = results
            .map((json) => PlaceModel.fromJson(json))
            .toList();

        // Sort by popularity (total visitor reviews)
        places.sort((a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal));
        return places;
      } else {
        throw Exception(AppStrings.errNearbyPlaces);
      }
    } catch (e) {
      print('Error fetching nearby popular places: $e');
      return [];
    }
  }

  Future<List<PlaceModel>> searchPlaces(
    String query,
    double? lat,
    double? lng,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getSearchPlacesUrl(query, lat: lat, lng: lng)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        List<PlaceModel> places = results
            .map((json) => PlaceModel.fromJson(json))
            .toList();
        places.sort((a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal));
        return places;
      } else {
        throw Exception(AppStrings.errSearchPlaces);
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  Future<PlaceModel?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getPlaceDetailsUrl(placeId)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        if (result != null) {
          PlaceModel place = PlaceModel.fromJson(result);
          // Enhance with mock details for the demo UI
          return _enhancePlaceWithDetails(place);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }

  PlaceModel _enhancePlaceWithDetails(PlaceModel place) {
    // We prioritize API data. The following are fallbacks for fields
    // not natively provided by the Google Places API free tier or specific results.
    return place.copyWith(
      description:
          place.description ??
          "${AppStrings.fbDescriptionPrefix}${place.name}${AppStrings.fbDescriptionSuffix}",
      city: place.city ?? AppStrings.fbCity,
      state: place.state ?? AppStrings.fbState,
      category: place.category ?? AppStrings.fbCategory,
      timings: place.timings ?? AppStrings.fbTimings,
      entryFee: place.entryFee ?? AppStrings.fbEntryFee,
      bestTimeToVisit: place.bestTimeToVisit ?? AppStrings.pdYearRound,
      difficulty: place.difficulty ?? AppStrings.pdEasy,
      parkingAvailable: place.parkingAvailable ?? true,
      suitableFor: place.suitableFor ?? AppStrings.fbSuitable,
      isOpen: place.isOpen, // Preserve the real open status from API
    );
  }
}
