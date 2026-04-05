import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/constants/app_assets.dart';

class ItineraryStep {
  final int day;
  final String title;
  final DateTime? date;
  final List<String> activities;

  ItineraryStep({
    required this.day,
    required this.title,
    this.date,
    this.activities = const [],
  });

  factory ItineraryStep.fromJson(Map<String, dynamic> json) {
    return ItineraryStep(
      day: json['day'] ?? 1,
      title: json['title'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
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
  final bool isVerified;

  OrganizerModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.role,
    this.rating = 0.0,
    this.tripsHosted = 0,
    this.isVerified = false,
  });

  factory OrganizerModel.fromJson(Map<String, dynamic> json) {
    return OrganizerModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Yatrikaa Guide',
      profileImage: json['profileImage'],
      role: json['role'] ?? 'Guide',
      rating: (json['rating'] ?? json['averageRating'] ?? 0.0).toDouble(),
      tripsHosted:
          json['packagesCount'] ??
          json['tripsCount'] ??
          json['tripsHosted'] ??
          0,
      isVerified:
          json['isVerified'] == true ||
          json['guideRequestStatus'] == 'Approved',
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
  final DateTime? startDate;
  final DateTime? endDate;

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
    this.startDate,
    this.endDate,
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
      organizer: (() {
        final Map<String, dynamic> orgJson = Map<String, dynamic>.from(
          (json['organizer'] is Map) ? json['organizer'] : {},
        );
        if (orgJson['rating'] == null && orgJson['averageRating'] == null) {
          orgJson['rating'] = ratings['average'];
        }
        return OrganizerModel.fromJson(orgJson);
      })(),
      status: json['status'] ?? 'Published',
      isPopular: json['isPopular'] ?? false,
      averageRating: (ratings['average'] ?? 0.0).toDouble(),
      reviewCount: ratings['count'] ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  TravelPackageModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    String? destinationName,
    double? lat,
    double? lng,
    int? days,
    int? nights,
    double? price,
    int? maxGroupSize,
    int? currentParticipants,
    String? difficulty,
    String? category,
    List<ItineraryStep>? itinerary,
    List<String>? inclusions,
    List<String>? exclusions,
    String? bestSeason,
    OrganizerModel? organizer,
    String? status,
    bool? isPopular,
    double? averageRating,
    int? reviewCount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TravelPackageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      destinationName: destinationName ?? this.destinationName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      days: days ?? this.days,
      nights: nights ?? this.nights,
      price: price ?? this.price,
      maxGroupSize: maxGroupSize ?? this.maxGroupSize,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      itinerary: itinerary ?? this.itinerary,
      inclusions: inclusions ?? this.inclusions,
      exclusions: exclusions ?? this.exclusions,
      bestSeason: bestSeason ?? this.bestSeason,
      organizer: organizer ?? this.organizer,
      status: status ?? this.status,
      isPopular: isPopular ?? this.isPopular,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'images': images,
      'destination': {
        'name': destinationName,
        'location': {'lat': lat, 'lng': lng},
      },
      'duration': {'days': days, 'nights': nights},
      'price': price,
      'maxGroupSize': maxGroupSize,
      'currentParticipants': currentParticipants,
      'difficulty': difficulty,
      'category': category,
      'itinerary': itinerary.map((i) => i.toJson()).toList(),
      'inclusions': inclusions,
      'exclusions': exclusions,
      'bestSeason': bestSeason,
      'organizer': organizer.toJson(),
      'status': status,
      'isPopular': isPopular,
      'ratings': {'average': averageRating, 'count': reviewCount},
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

extension ItineraryStepJson on ItineraryStep {
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'date': date?.toIso8601String(),
      'activities': activities,
    };
  }
}

extension OrganizerModelJson on OrganizerModel {
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'profileImage': profileImage,
      'role': role,
      'rating': rating,
      'tripsHosted': tripsHosted,
      'isVerified': isVerified,
    };
  }
}
