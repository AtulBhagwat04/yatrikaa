import '../constants/api_constants.dart';

class PlaceModel {
  final String id;
  final String name;
  final String? address;
  final double rating;
  final int userRatingsTotal;
  final String? photoReference;
  final double lat;
  final double lng;
  final double? distance;
  final String? icon;

  PlaceModel({
    required this.id,
    required this.name,
    this.address,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    this.photoReference,
    required this.lat,
    required this.lng,
    this.distance,
    this.icon,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry != null ? geometry['location'] : null;

    return PlaceModel(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      photoReference: json['photos'] != null && json['photos'].isNotEmpty
          ? json['photos'][0]['photo_reference']
          : null,
      lat: (location != null ? location['lat'] : 0.0).toDouble(),
      lng: (location != null ? location['lng'] : 0.0).toDouble(),
      distance: (json['distanceCalculated'] != null)
          ? (json['distanceCalculated'] as num).toDouble()
          : null,
      icon: json['icon'],
    );
  }

  String get photoUrl => photoReference != null
      ? ApiConstants.getPhotoUrl(photoReference!)
      : 'https://via.placeholder.com/400x300?text=No+Image';
}
