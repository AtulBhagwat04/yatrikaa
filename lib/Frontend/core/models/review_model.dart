import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/constants/app_assets.dart';

class ReviewModel {
  final String? id;
  final String? userId;
  final String authorName;
  final String? profilePhotoUrl;
  final double rating;
  final String relativeTimeDescription;
  final String text;
  final int? time;

  ReviewModel({
    this.id,
    this.userId,
    required this.authorName,
    this.profilePhotoUrl,
    required this.rating,
    required this.relativeTimeDescription,
    required this.text,
    this.time,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Handle internal user object if present
    final user = json['user'];
    final name = (user is Map) ? user['name'] : (json['author_name'] ?? json['authorName']);
    final photo = (user is Map) ? user['profilePicture'] : (json['profile_photo_url'] ?? json['profilePhotoUrl']);
    
    // Multiple fallbacks for userId to ensure reliability
    String? userId;
    if (user is Map) {
      userId = (user['_id'] ?? user['id'])?.toString();
    } else if (user != null) {
      userId = user.toString();
    } else {
      userId = (json['userId'] ?? json['user_id'] ?? json['author_id'])?.toString();
    }

    return ReviewModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      userId: userId,
      authorName: name ?? AppStrings.pdAnonymous,
      profilePhotoUrl: photo,
      rating: (json['rating'] ?? 0.0).toDouble(),
      relativeTimeDescription: json['relative_time_description'] ??
          (json['createdAt'] != null ? 'Recently' : ''),
      text: json['comment'] ?? json['text'] ?? '',
      time: json['time'] is int ? json['time'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_name': authorName,
      'profile_photo_url': profilePhotoUrl,
      'rating': rating,
      'relative_time_description': relativeTimeDescription,
      'text': text,
      if (time != null) 'time': time,
    };
  }

  String get displayProfilePhoto {
    if (profilePhotoUrl == null || profilePhotoUrl!.isEmpty) {
      return AppAssets.placeholderImageUrl;
    }
    if (profilePhotoUrl!.startsWith('http')) {
      return profilePhotoUrl!;
    }
    return ApiConstants.getPhotoUrl(profilePhotoUrl!);
  }
}
