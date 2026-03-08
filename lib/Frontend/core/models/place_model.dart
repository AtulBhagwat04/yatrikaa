import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_assets.dart';

class ReviewModel {
  final String authorName;
  final String? profilePhotoUrl;
  final double rating;
  final String relativeTimeDescription;
  final String text;

  ReviewModel({
    required this.authorName,
    this.profilePhotoUrl,
    required this.rating,
    required this.relativeTimeDescription,
    required this.text,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      authorName: json['author_name'] ?? AppStrings.pdAnonymous,
      profilePhotoUrl: json['profile_photo_url'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      relativeTimeDescription: json['relative_time_description'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class PlaceModel {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? category;
  final String? description;
  final List<String> images;
  final double rating;
  final int userRatingsTotal;
  final String? photoReference;
  final double lat;
  final double lng;
  final double? distance;
  final String? icon;

  // Extra details
  final String? timings;
  final String? entryFee;
  final String? bestTimeToVisit;
  final String? difficulty;
  final bool? parkingAvailable;
  final String? suitableFor;
  final bool? photographyAllowed;
  final List<String>? facilities;
  final List<PlaceModel> nearbyPlaces;
  final List<ReviewModel> reviews;
  final String? website;
  final bool? isOpen;

  PlaceModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.category,
    this.description,
    this.images = const [],
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    this.photoReference,
    required this.lat,
    required this.lng,
    this.distance,
    this.icon,
    this.timings,
    this.entryFee,
    this.bestTimeToVisit,
    this.difficulty,
    this.parkingAvailable,
    this.suitableFor,
    this.photographyAllowed,
    this.facilities,
    this.nearbyPlaces = const [],
    this.reviews = const [],
    this.website,
    this.isOpen,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry != null ? geometry['location'] : null;

    // Extract images if available
    // Extract images if available - Filter for High Quality Only
    List<String> imagesList = [];
    if (json['photos'] != null && json['photos'] is List) {
      imagesList = (json['photos'] as List)
          .where((p) {
            final width = p['width'] as int? ?? 0;
            final height = p['height'] as int? ?? 0;
            return p['photo_reference'] != null &&
                (width >= 500 || height >= 500);
          })
          .map((p) => p['photo_reference'] as String)
          .take(10)
          .toList();
    }

    // Fallback to 'images' if 'photos' is empty or null
    if (imagesList.isEmpty && json['images'] != null && json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    }

    // Extract City and State from address_components
    String? city;
    String? state;
    if (json['address_components'] != null &&
        json['address_components'] is List) {
      final comps = json['address_components'] as List;
      for (var comp in comps) {
        final types = comp['types'] as List;
        if (types.contains('locality')) {
          city = comp['long_name'];
        } else if (types.contains('administrative_area_level_1')) {
          state = comp['long_name'];
        }
      }
    }

    // Fallback extract city from formatted_address if locality is missing
    if (city == null && json['formatted_address'] != null) {
      final parts = (json['formatted_address'] as String).split(',');
      if (parts.length >= 3) {
        city = parts[parts.length - 3].trim();
      }
    }

    // Extract Description from editorial_summary
    String? description;
    if (json['editorial_summary'] != null) {
      description = json['editorial_summary']['overview'];
    } else if (json['description'] != null) {
      description = json['description'];
    }

    // Extract Category from types
    String? category;
    if (json['types'] != null && json['types'] is List) {
      final types = json['types'] as List;
      final interestingTypes = types
          .where(
            (t) =>
                t != 'point_of_interest' &&
                t != 'establishment' &&
                t != 'tourist_attraction',
          )
          .toList();
      if (interestingTypes.isNotEmpty) {
        String type = interestingTypes.first.toString().replaceAll('_', ' ');
        category = type[0].toUpperCase() + type.substring(1);
      } else if (types.isNotEmpty) {
        String type = types.first.toString().replaceAll('_', ' ');
        category = type[0].toUpperCase() + type.substring(1);
      }
    }

    // Extract Timings
    String? timings;
    if (json['opening_hours'] != null) {
      if (json['opening_hours']['weekday_text'] != null &&
          json['opening_hours']['weekday_text'] is List) {
        final weekdayText = json['opening_hours']['weekday_text'] as List;
        timings = weekdayText.isNotEmpty
            ? weekdayText.first
            : AppStrings.pdOpenNowAlt;
      } else {
        timings = json['opening_hours']['open_now'] == true
            ? AppStrings.pdOpenNow
            : AppStrings.pdClosed;
      }
    }

    // Extract Reviews
    List<ReviewModel> reviewsList = [];
    if (json['reviews'] != null && json['reviews'] is List) {
      reviewsList = (json['reviews'] as List)
          .map((r) => ReviewModel.fromJson(r))
          .toList();
    }

    // Extract Open Status
    bool? isOpen;
    if (json['opening_hours'] != null) {
      isOpen = json['opening_hours']['open_now'];
    }

    return PlaceModel(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'],
      city: city ?? json['city'],
      state: state ?? json['state'],
      category: category ?? json['category'],
      description: description,
      images: imagesList,
      rating: (json['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      photoReference: imagesList.isNotEmpty ? imagesList[0] : null,
      lat: (location != null ? location['lat'] : 0.0).toDouble(),
      lng: (location != null ? location['lng'] : 0.0).toDouble(),
      distance: (json['distanceCalculated'] != null)
          ? (json['distanceCalculated'] as num).toDouble()
          : null,
      icon: json['icon'],
      timings: timings,
      entryFee: json['entry_fee'],
      bestTimeToVisit: json['best_time'],
      difficulty: json['difficulty'],
      parkingAvailable: json['parking_available'],
      suitableFor: json['suitable_for'],
      photographyAllowed: json['photography_allowed'],
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : null,
      reviews: reviewsList,
      website: json['website'],
      isOpen: isOpen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': id,
      'name': name,
      'formatted_address': address,
      'city': city,
      'state': state,
      'category': category,
      'description': description,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'photo_reference': photoReference,
      'lat': lat,
      'lng': lng,
      'timings': timings,
      'entry_fee': entryFee,
      'best_time': bestTimeToVisit,
      'difficulty': difficulty,
      'parking_available': parkingAvailable,
      'suitable_for': suitableFor,
      'website': website,
    };
  }

  PlaceModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? category,
    String? description,
    List<String>? images,
    double? rating,
    int? userRatingsTotal,
    String? photoReference,
    double? lat,
    double? lng,
    double? distance,
    String? icon,
    String? timings,
    String? entryFee,
    String? bestTimeToVisit,
    String? difficulty,
    bool? parkingAvailable,
    String? suitableFor,
    List<PlaceModel>? nearbyPlaces,
    List<ReviewModel>? reviews,
    String? website,
    bool? isOpen,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      category: category ?? this.category,
      description: description ?? this.description,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      photoReference: photoReference ?? this.photoReference,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distance: distance ?? this.distance,
      icon: icon ?? this.icon,
      timings: timings ?? this.timings,
      entryFee: entryFee ?? this.entryFee,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      difficulty: difficulty ?? this.difficulty,
      parkingAvailable: parkingAvailable ?? this.parkingAvailable,
      suitableFor: suitableFor ?? this.suitableFor,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      reviews: reviews ?? this.reviews,
      website: website ?? this.website,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  String get photoUrl {
    if (photoReference == null) return AppAssets.placeholderImageUrl;
    if (photoReference!.startsWith('http')) return photoReference!;
    return ApiConstants.getPhotoUrl(photoReference!);
  }

  List<String> get allPhotoUrls {
    if (images.isEmpty) return [photoUrl];
    return images.map((img) {
      if (img.startsWith('http')) return img;
      return ApiConstants.getPhotoUrl(img);
    }).toList();
  }
}
