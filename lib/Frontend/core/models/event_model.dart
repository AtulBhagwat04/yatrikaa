import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:yatrikaa/Frontend/core/constants/app_assets.dart';

class EventModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final String venue;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final List<String> images;
  final String? organizer;
  final String entryFee;
  final String? contactNumber;
  final String? website;
  final bool isPopular;
  final bool isVerified;
  final String? createdBy;
  final int interestedCount;
  final List<String> interestedUsers;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.venue,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    this.images = const [],
    this.organizer,
    this.entryFee = 'Free',
    this.contactNumber,
    this.website,
    this.isPopular = false,
    this.isVerified = false,
    this.createdBy,
    this.interestedCount = 0,
    this.interestedUsers = const [],
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    date,
    startTime,
    endTime,
    venue,
    address,
    lat,
    lng,
    category,
    images,
    organizer,
    entryFee,
    contactNumber,
    website,
    isPopular,
    isVerified,
    createdBy,
    interestedCount,
    interestedUsers,
  ];

  factory EventModel.fromJson(Map<String, dynamic> json) {
    try {
      dynamic geometry = json['geometry'];
      if (geometry is String && geometry.isNotEmpty) {
        try {
          geometry = jsonDecode(geometry);
        } catch (e) {
          debugPrint('Error parsing geometry string in EventModel: $e');
        }
      }

      final location = (geometry != null && geometry is Map)
          ? geometry['location']
          : null;

      return EventModel(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        startTime: json['startTime'] ?? '',
        endTime: json['endTime'],
        venue: json['venue'] ?? '',
        address: json['address'] ?? '',
        lat: (location != null && location is Map
            ? (location['lat'] as num?)?.toDouble() ?? 0.0
            : 0.0),
        lng: (location != null && location is Map
            ? (location['lng'] as num?)?.toDouble() ?? 0.0
            : 0.0),
        category: json['category'] ?? '',
        images: json['images'] != null ? List<String>.from(json['images']) : [],
        organizer: json['organizer'],
        entryFee: json['entryFee'] ?? 'Free',
        contactNumber: json['contactNumber']?.toString(),
        website: json['website'],
        isPopular: json['isPopular'] ?? false,
        isVerified: json['isVerified'] ?? false,
        createdBy: json['createdBy'] is Map
            ? json['createdBy']['_id']
            : json['createdBy'],
        interestedCount: (json['interestedCount'] as num?)?.toInt() ?? 0,
        interestedUsers: json['interestedUsers'] != null
            ? (json['interestedUsers'] as List)
                  .map((e) => e is Map ? (e['_id'] as String) : (e as String))
                  .toList()
            : [],
      );
    } catch (e) {
      print('Error parsing EventModel: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'venue': venue,
      'address': address,
      'geometry': {
        'location': {'lat': lat, 'lng': lng},
      },
      'category': category,
      'images': images,
      'organizer': organizer,
      'entryFee': entryFee,
      'contactNumber': contactNumber,
      'website': website,
      'isPopular': isPopular,
      'isVerified': isVerified,
      'interestedCount': interestedCount,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? venue,
    String? address,
    double? lat,
    double? lng,
    String? category,
    List<String>? images,
    String? organizer,
    String? entryFee,
    String? contactNumber,
    String? website,
    bool? isPopular,
    bool? isVerified,
    String? createdBy,
    int? interestedCount,
    List<String>? interestedUsers,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      category: category ?? this.category,
      images: images ?? this.images,
      organizer: organizer ?? this.organizer,
      entryFee: entryFee ?? this.entryFee,
      contactNumber: contactNumber ?? this.contactNumber,
      website: website ?? this.website,
      isPopular: isPopular ?? this.isPopular,
      isVerified: isVerified ?? this.isVerified,
      createdBy: createdBy ?? this.createdBy,
      interestedCount: interestedCount ?? this.interestedCount,
      interestedUsers: interestedUsers ?? this.interestedUsers,
    );
  }

  String get imageUrl =>
      images.isNotEmpty ? images.first : AppAssets.placeholderImageUrl;
}
