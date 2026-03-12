import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_assets.dart';

class ItineraryStep {
  final int day;
  final String title;
  final List<String> activities;

  ItineraryStep({
    required this.day,
    required this.title,
    this.activities = const [],
  });

  factory ItineraryStep.fromJson(Map<String, dynamic> json) {
    return ItineraryStep(
      day: json['day'] ?? 1,
      title: json['title'] ?? '',
      activities: List<String>.from(json['activities'] ?? []),
    );
  }
}

class OrganizerModel {
  final String id;
  final String name;
  final String? profileImage;
  final String role;
  final double rating;
  final int tripsHosted;

  OrganizerModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.role,
    this.rating = 0.0,
    this.tripsHosted = 0,
  });

  factory OrganizerModel.fromJson(Map<String, dynamic> json) {
    return OrganizerModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Bhatkanti Guide',
      profileImage: json['profileImage'],
      role: json['role'] ?? 'Guide',
      rating: (json['rating'] ?? 0.0).toDouble(),
      tripsHosted: json['tripsHosted'] ?? 0,
    );
  }
}

class TravelPackageModel {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String destinationName;
  final double lat;
  final double lng;
  final int days;
  final int nights;
  final double price;
  final int maxGroupSize;
  final int currentParticipants;
  final String difficulty;
  final String category;
  final List<ItineraryStep> itinerary;
  final List<String> inclusions;
  final List<String> exclusions;
  final String? bestSeason;
  final OrganizerModel organizer;
  final String status;
  final bool isPopular;
  final double averageRating;
  final int reviewCount;

  TravelPackageModel({
    required this.id,
    required this.title,
    required this.description,
    this.images = const [],
    required this.destinationName,
    required this.lat,
    required this.lng,
    required this.days,
    this.nights = 0,
    required this.price,
    required this.maxGroupSize,
    this.currentParticipants = 0,
    required this.difficulty,
    required this.category,
    this.itinerary = const [],
    this.inclusions = const [],
    this.exclusions = const [],
    this.bestSeason,
    required this.organizer,
    this.status = 'Published',
    this.isPopular = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory TravelPackageModel.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'] ?? {};
    final location = destination['location'] ?? {};
    final duration = json['duration'] ?? {};
    final ratings = json['ratings'] ?? {};

    return TravelPackageModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      destinationName: destination['name'] ?? '',
      lat: (location['lat'] ?? 0.0).toDouble(),
      lng: (location['lng'] ?? 0.0).toDouble(),
      days: duration['days'] ?? 1,
      nights: duration['nights'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      maxGroupSize: json['maxGroupSize'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      difficulty: json['difficulty'] ?? 'Moderate',
      category: json['category'] ?? 'Adventure',
      itinerary: (json['itinerary'] as List? ?? [])
          .map((i) => ItineraryStep.fromJson(i))
          .toList(),
      inclusions: List<String>.from(json['inclusions'] ?? []),
      exclusions: List<String>.from(json['exclusions'] ?? []),
      bestSeason: json['bestSeason'],
      organizer: OrganizerModel.fromJson(json['organizer'] ?? {}),
      status: json['status'] ?? 'Published',
      isPopular: json['isPopular'] ?? false,
      averageRating: (ratings['average'] ?? 0.0).toDouble(),
      reviewCount: ratings['count'] ?? 0,
    );
  }

  String get mainPhotoUrl {
    if (images.isEmpty) return AppAssets.placeholderImageUrl;
    if (images.first.startsWith('http')) return images.first;
    return ApiConstants.getPhotoUrl(images.first);
  }

  List<String> get allPhotoUrls {
    if (images.isEmpty) return [AppAssets.placeholderImageUrl];
    return images.map((img) {
      if (img.startsWith('http')) return img;
      return ApiConstants.getPhotoUrl(img);
    }).toList();
  }
}
