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
    String url = '$baseUrl/places/search?query=$query';
    if (lat != null && lng != null) {
      url += '&lat=$lat&lng=$lng';
    }
    return url;
  }

  static String getPhotoUrl(String photoReference) {
    return '$baseUrl/places/photo/$photoReference';
  }
}
