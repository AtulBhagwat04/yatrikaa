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
  const TravelPackagesRequested({this.category = 'All', this.search = ''});
  @override
  List<Object?> get props => [category, search];
}

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
  const TravelPackageDetailRequested(this.packageId);
  @override
  List<Object?> get props => [packageId];
}

/// Load packages created by the logged-in guide.
class TravelMyPackagesRequested extends TravelEvent {}

// ── Booking Events ─────────────────────────────────────────────────────────

/// Load the logged-in user's bookings.
class TravelMyBookingsRequested extends TravelEvent {}

/// Submit a join / booking request.
class TravelJoinRequested extends TravelEvent {
  final String packageId;
  final List<Map<String, dynamic>> travelers;
  final String contactNumber;
  final String? notes;
  const TravelJoinRequested({
    required this.packageId,
    required this.travelers,
    required this.contactNumber,
    this.notes,
  });
  @override
  List<Object?> get props => [packageId, travelers, contactNumber];
}

/// Cancel an existing booking.
class TravelCancelBookingRequested extends TravelEvent {
  final String bookingId;
  const TravelCancelBookingRequested(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

/// Clear any error / join success state after it has been consumed.
class TravelStatusReset extends TravelEvent {}
