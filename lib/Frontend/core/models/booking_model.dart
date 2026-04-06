import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';

/// Lightweight booking model returned by the API.
/// A booking links a User → TravelPackage with traveler details and status.
class BookingModel {
  final String id;
  final String status; // Pending | Confirmed | Cancelled | Completed
  final String paymentStatus; // Pending | Paid | Refunded
  final double totalAmount;
  final String contactNumber;
  final String? notes;
  final DateTime bookingDate;
  final List<TravelerModel> travelers;

  // Populated package reference (partial)
  final TravelPackageModel? package;

  // Raw package fields (when package is returned as a nested object)
  final String packageId;
  final String packageTitle;
  final String packageImage;
  final String destinationName;
  final String organiserName;
  final String? userName;

  BookingModel({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.contactNumber,
    this.notes,
    required this.bookingDate,
    required this.travelers,
    this.package,
    required this.packageId,
    required this.packageTitle,
    required this.packageImage,
    required this.destinationName,
    required this.organiserName,
    this.userName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    TravelPackageModel? pkg;
    String pkgId = '';
    String pkgTitle = '';
    String pkgImage = '';
    String destName = '';
    String orgName = '';

    final rawPkg = json['package'];
    if (rawPkg is Map<String, dynamic>) {
      try {
        pkg = TravelPackageModel.fromJson(rawPkg);
        pkgId = pkg.id;
        pkgTitle = pkg.title;
        pkgImage = pkg.mainPhotoUrl;
        destName = pkg.destinationName;
        orgName = pkg.organizer.name;
      } catch (_) {
        pkgId = rawPkg['_id']?.toString() ?? '';
        pkgTitle = rawPkg['title'] ?? '';
        destName = (rawPkg['destination'] is Map)
            ? (rawPkg['destination']['name'] ?? '')
            : '';
      }
    } else if (rawPkg is String) {
      pkgId = rawPkg;
    }

    final travelersJson = json['travelers'] as List? ?? [];
    final travelers = travelersJson
        .map<TravelerModel>((t) => TravelerModel.fromJson(t as Map<String, dynamic>))
        .toList();

    return BookingModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      status: json['status'] ?? 'Pending',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      contactNumber: json['contactNumber'] ?? '',
      notes: json['notes'],
      bookingDate: json['bookingDate'] != null
          ? DateTime.tryParse(json['bookingDate']) ?? DateTime.now()
          : DateTime.now(),
      travelers: travelers,
      package: pkg,
      packageId: pkgId,
      packageTitle: pkgTitle,
      packageImage: pkgImage,
      destinationName: destName,
      organiserName: orgName,
      userName: json['user'] is Map ? json['user']['name'] : json['userName'],
    );
  }
}

class TravelerModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String status;

  TravelerModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.status,
  });

  factory TravelerModel.fromJson(Map<String, dynamic> json) {
    return TravelerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      age: json['age'] is num ? (json['age'] as num).toInt() : 18,
      gender: json['gender'] ?? 'Other',
      status: json['status'] ?? 'Pending',
    );
  }
}
