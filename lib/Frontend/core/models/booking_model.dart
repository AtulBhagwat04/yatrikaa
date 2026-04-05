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
        destName = rawPkg['destination']?['name'] ?? '';
      }
    } else if (rawPkg is String) {
      pkgId = rawPkg;
    }

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
