import 'dart:async';
import 'package:http/http.dart' as http;

class ApiConstants {
  // Local Backend URL
  static const String localUrl = 'http://10.63.28.64:3000/api';

  // Render Deployed Backend URL
  static const String liveUrl =
      'https://bhatkanti-backend-8msl.onrender.com/api';

  static String baseUrl = liveUrl;

  // ── Auth & Users
  static String getGuideRequestsUrl() => '$baseUrl/auth/guide-requests';
  static String getHandleGuideRequestUrl() =>
      '$baseUrl/auth/guide-requests/handle';
  static String getRequestGuideRoleUrl() => '$baseUrl/auth/request-guide';

  // Automatic Fallback Logic
  static Future<void> checkServerAvailability() async {
    // Health check hits /health directly, NOT /api/health
    // localUrl is 'http://10.15.157.64:3000/api', so we remove '/api' for the health check
    final localHealthUrl = localUrl.replaceAll('/api', '') + '/health';
    try {
      print('Checking local backend at $localHealthUrl...');
      final response = await http
          .get(Uri.parse(localHealthUrl))
          .timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () => http.Response('Timeout', 408),
          );

      if (response.statusCode == 200) {
        baseUrl = localUrl;
        print('Local backend is running. Using: $baseUrl');
      } else {
        baseUrl = liveUrl;
        print('Local backend returned error. Falling back to Render: $baseUrl');
      }
    } catch (e) {
      baseUrl = liveUrl;
      print('Local backend not reachable. Falling back to Render: $baseUrl');
    }
  }

  static String getNearbyPlacesUrl(
    double lat,
    double lng, {
    int radius = 5000,
    String type = 'tourist_attraction',
  }) {
    return '$baseUrl/places/nearby?lat=$lat&lng=$lng&radius=$radius&type=$type';
  }

  static String getSearchPlacesUrl(String query, {double? lat, double? lng}) {
    final encodedQuery = Uri.encodeComponent(query);
    String url = '$baseUrl/places/search?query=$encodedQuery';
    if (lat != null && lng != null) {
      url += '&lat=$lat&lng=$lng';
    }
    return url;
  }

  static String getPlaceDetailsUrl(String placeId) {
    return '$baseUrl/places/details/$placeId';
  }

  static String getPopularPlacesUrl() {
    return '$baseUrl/places/popular';
  }

  static String getPhotoUrl(String photoReference) {
    if (photoReference.startsWith('http')) return photoReference;
    return '$baseUrl/places/photo/$photoReference';
  }

  static const String eventsDiscoveryQuery =
      "Upcoming cultural festivals events and fairs in Maharashtra";

  // category queries for discovery
  static const Map<String, String> categoryQueries = {
    'Forts':
        'Famous historical forts in Maharashtra Raigad Pratapgad Janjira Shivneri',
    'Beaches':
        'Popular blue flag beaches Konkan Malvan Alibaug Ganpatipule Maharashtra',
    'Temples':
        'Famous ancient spiritual temples Maharashtra Jyotirlinga Ashtavinayak',
    'Hill Stations':
        'Popular hill stations Western Ghats Mahabaleshwar Lonavala Matheran',
    'Caves':
        'Ancient heritage caves Ajanta Ellora Elephanta Kanheri Maharashtra',
    'Waterfalls':
        'Famous waterfalls Maharashtra Western Ghats Sahyadri monsoons',
    'Museums': 'Top history museums Pune Mumbai Nagpur Maharashtra heritage',
    'Wildlife': 'Popular wildlife sanctuaries Tadoba Melghat Pench Maharashtra',
    'Lakes': 'Famous serene lakes Maharashtra Lonar Rankala Venna Pawna',
    'Trekking': 'Top trek points Sahyadri mountains Maharashtra adventure',
    'UNESCO Sites':
        'UNESCO World Heritage sites Maharashtra Ajanta Ellora Elephanta',
    'Spiritual':
        'Shirdi Sai Baba Temple Shani Shingnapur Pandharpur Vithal Temple',
  };

  // ── Travel Packages ────────────────────────────────────────────────────────
  static String getPackagesUrl({String? category, String? search}) {
    String url = '$baseUrl/packages';
    final List<String> params = [];
    if (category != null && category != 'All') {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return url;
  }

  static String getPackageDetailUrl(String id) => '$baseUrl/packages/$id';
  static String getMyPackagesUrl() => '$baseUrl/packages/my';
  static String getJoinPackageUrl(String id) => '$baseUrl/packages/$id/join';
  static String getMyBookingsUrl() => '$baseUrl/packages/bookings/mine';
  static String getGuideAllBookingsUrl() => '$baseUrl/packages/bookings/organizer';
  static String getCancelBookingUrl(String bookingId) =>
      '$baseUrl/packages/bookings/$bookingId/cancel';
  static String getConfirmBookingUrl(String bookingId) =>
      '$baseUrl/packages/bookings/$bookingId/confirm';
  static String getPackageParticipantsUrl(String id) =>
      '$baseUrl/packages/$id/participants';
  static String getPublishPackageUrl(String id) =>
      '$baseUrl/packages/admin/$id/publish';
  static String getAdminAllPackagesUrl() => '$baseUrl/packages/admin/all';
}
