import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../constants/api_constants.dart';

class PlacesService {
  Future<List<PlaceModel>> getFamousMaharashtraPlaces() async {
    try {
      // Define distinct categories with user-requested iconic landmarks
      final categoryQueries = {
        'Historical': 'Taj Mahal Gateway of India Raigad Fort Lal Mahal Pune',
        'Spiritual':
            'Shirdi Sai Baba Temple Dagdusheth Ganpati Kolhapur Ambabai Temple',
        'Nature': 'Malvan Beach Konkan Goa Beaches Lonavala Hill Station',
        'Leisure': 'Rankala Lake Kolhapur Imagica Water Park Wet n Joy',
        'Heritage': 'Ajanta Ellora Caves Hampi UNESCO Sites India',
      };

      // Fetch all queries in parallel
      final Map<String, http.Response> responses = {};
      final List<String> keys = categoryQueries.keys.toList();

      final fetchedResponses = await Future.wait(
        keys.map(
          (key) => http.get(
            Uri.parse(ApiConstants.getSearchPlacesUrl(categoryQueries[key]!)),
          ),
        ),
      );

      for (int i = 0; i < keys.length; i++) {
        responses[keys[i]] = fetchedResponses[i];
      }

      Map<String, List<PlaceModel>> categoryResults = {};

      // Parse and filter each category
      for (var entry in responses.entries) {
        if (entry.value.statusCode == 200) {
          final data = json.decode(entry.value.body);
          final List results = data['results'] ?? [];
          List<PlaceModel> places = results
              .map((json) => PlaceModel.fromJson(json))
              .toList();

          // Filter for high quality (Rating >= 4.0)
          places = places.where((p) => p.rating >= 4.0).toList();

          // SHUFFLE each category pool individually so that we pick
          // DIFFERENT famous places from that category on every refresh
          places.shuffle();

          categoryResults[entry.key] = places;
        }
      }

      // 1. Strictly merge all category results into one pool
      List<PlaceModel> allFoundPlaces = [];
      for (var list in categoryResults.values) {
        allFoundPlaces.addAll(list);
      }

      // 2. REMOVE DUPLICATES - Crucial to prevent same place appearing from different queries
      final uniqueIds = <String>{};
      allFoundPlaces.retainWhere((place) => uniqueIds.add(place.id));

      // 3. GLOBAL SHUFFLE - Ensures we don't always pick the same "top" places
      allFoundPlaces.shuffle();

      // 4. PICK 15-20 FRESH PLACES - This ensures a manageable but diverse list
      List<PlaceModel> diversePlaces = allFoundPlaces.take(20).toList();

      return diversePlaces;
    } catch (e) {
      print('Error fetching unique interleaved places: $e');
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
            'Popular tourist attractions famous places',
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
        throw Exception('Failed to load nearby popular places');
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
        throw Exception('Failed to search places');
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
}
