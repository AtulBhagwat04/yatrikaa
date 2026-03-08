class ApiConstants {
  // Use your computer's IP address instead of localhost for physical devices
  // Current IP: 10.15.157.64
  static const String baseUrl = 'http://10.15.157.64:3000/api';

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
}
