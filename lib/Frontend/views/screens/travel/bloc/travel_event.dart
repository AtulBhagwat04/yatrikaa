import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class TravelEvent extends Equatable {
  const TravelEvent();
  @override
  List<Object?> get props => [];
}

// ── Package Events ─────────────────────────────────────────────────────────

/// Load the initial packages list on screen start.
class TravelPackagesRequested extends TravelEvent {
  final String category;
  final String search;
  final bool isSilent;
  const TravelPackagesRequested({
    this.category = 'All',
    this.search = '',
    this.isSilent = false,
  });
  @override
  List<Object?> get props => [category, search, isSilent];
}

class TravelLoadMorePackages extends TravelEvent {}

class TravelLoadCache extends TravelEvent {}

/// Filter by category (chip tap).
class TravelCategoryChanged extends TravelEvent {
  final String category;
  const TravelCategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}

/// Update search text.
class TravelSearchChanged extends TravelEvent {
  final String query;
  const TravelSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

/// Load details for a specific package.
class TravelPackageDetailRequested extends TravelEvent {
  final String packageId;
  final bool isSilent;
  const TravelPackageDetailRequested(this.packageId, {this.isSilent = false});
  @override
  List<Object?> get props => [packageId, isSilent];
}

/// Load packages created by the logged-in guide.
class TravelMyPackagesRequested extends TravelEvent {}

/// Load next page of my packages.
class TravelLoadMoreMyPackages extends TravelEvent {}

class TravelDeletePackageRequested extends TravelEvent {
  final String packageId;
  const TravelDeletePackageRequested(this.packageId);
  @override
  List<Object?> get props => [packageId];
}

class TravelUpdatePackageRequested extends TravelEvent {
  final String packageId;
  final Map<String, dynamic> body;
  final List<File> imageFiles;
  const TravelUpdatePackageRequested({
    required this.packageId,
    required this.body,
    this.imageFiles = const [],
  });
  @override
  List<Object?> get props => [packageId, body, imageFiles];
}

class TravelCreatePackageRequested extends TravelEvent {
  final Map<String, dynamic> body;
  final List<File> imageFiles;
  const TravelCreatePackageRequested({
    required this.body,
    this.imageFiles = const [],
  });
  @override
  List<Object?> get props => [body, imageFiles];
}

// ── Booking Events ─────────────────────────────────────────────────────────

/// Load the logged-in user's bookings.
class TravelMyBookingsRequested extends TravelEvent {}

/// Submit a join / booking request.
class TravelJoinRequested extends TravelEvent {
  final String packageId;
  final String guideName;
  final List<Map<String, dynamic>> travelers;
  final String contactNumber;
  final String? notes;
  const TravelJoinRequested({
    required this.packageId,
    required this.guideName,
    required this.travelers,
    required this.contactNumber,
    this.notes,
  });
  @override
  List<Object?> get props => [packageId, guideName, travelers, contactNumber];
}

/// Cancel an existing booking.
class TravelCancelBookingRequested extends TravelEvent {
  final String bookingId;
  const TravelCancelBookingRequested(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

/// Load packages for admin review.
class TravelAdminReviewRequested extends TravelEvent {
  final String? status;
  const TravelAdminReviewRequested({this.status});
  @override
  List<Object?> get props => [status];
}

/// Load next page of admin packages.
class TravelLoadMoreAdminPackages extends TravelEvent {
  final String? status;
  const TravelLoadMoreAdminPackages({this.status});
  @override
  List<Object?> get props => [status];
}

/// Admin action to publish a package.
class TravelPublishPackageRequested extends TravelEvent {
  final String packageId;
  const TravelPublishPackageRequested(this.packageId);
  @override
  List<Object?> get props => [packageId];
}

/// Admin action to load guide requests.
class TravelGuideRequestsRequested extends TravelEvent {}

/// Admin action to approve / reject guide request.
class TravelHandleGuideRequested extends TravelEvent {
  final String userId;
  final String action; // 'approve' or 'reject'
  const TravelHandleGuideRequested({
    required this.userId,
    required this.action,
  });
  @override
  List<Object?> get props => [userId, action];
}

// ── Guide Booking Management ──────────────────────────────────────────────
class TravelPackageParticipantsRequested extends TravelEvent {
  final String packageId;
  const TravelPackageParticipantsRequested(this.packageId);
  @override
  List<Object?> get props => [packageId];
}

class TravelAllGuideBookingsRequested extends TravelEvent {}

class TravelHandleBookingRequested extends TravelEvent {
  final String bookingId;
  final String action; // 'Confirmed' or 'Cancelled'
  const TravelHandleBookingRequested({
    required this.bookingId,
    required this.action,
  });
  @override
  List<Object?> get props => [bookingId, action];
}

class TravelHandleTravelerStatusRequested extends TravelEvent {
  final String bookingId;
  final String travelerId;
  final String status; // 'Confirmed' or 'Cancelled' or 'CancellationRequested'
  const TravelHandleTravelerStatusRequested({
    required this.bookingId,
    required this.travelerId,
    required this.status,
  });
  @override
  List<Object?> get props => [bookingId, travelerId, status];
}

class TravelCancelTravelerRequested extends TravelEvent {
  final String bookingId;
  final String travelerId;
  const TravelCancelTravelerRequested({
    required this.bookingId,
    required this.travelerId,
  });
  @override
  List<Object?> get props => [bookingId, travelerId];
}

/// Clear any error / join success state after it has been consumed.
class TravelStatusReset extends TravelEvent {}
