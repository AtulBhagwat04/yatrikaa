import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/services/packages_service.dart';
import 'package:bhatkanti_app/Frontend/core/models/booking_model.dart';
import 'travel_event.dart';
import 'travel_state.dart';

class TravelBloc extends Bloc<TravelEvent, TravelState> {
  final PackagesService _service = PackagesService();

  TravelBloc() : super(const TravelState()) {
    on<TravelPackagesRequested>(_onPackagesRequested);
    on<TravelCategoryChanged>(_onCategoryChanged);
    on<TravelSearchChanged>(_onSearchChanged);
    on<TravelPackageDetailRequested>(_onDetailRequested);
    on<TravelMyPackagesRequested>(_onMyPackagesRequested);
    on<TravelMyBookingsRequested>(_onMyBookingsRequested);
    on<TravelJoinRequested>(_onJoinRequested);
    on<TravelCancelBookingRequested>(_onCancelBookingRequested);
    on<TravelStatusReset>(_onStatusReset);
  }

  // ── Package Discovery ──────────────────────────────────────────────────────

  Future<void> _onPackagesRequested(
    TravelPackagesRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(packagesStatus: TravelStatus.loading));
    try {
      final packages = await _service.getPackages(
        category: event.category == 'All' ? null : event.category,
        search: event.search.isEmpty ? null : event.search,
      );
      emit(state.copyWith(
        packagesStatus: TravelStatus.success,
        packages: packages,
        selectedCategory: event.category,
        searchQuery: event.search,
      ));
    } catch (e) {
      emit(state.copyWith(
        packagesStatus: TravelStatus.failure,
        packagesError: e.toString(),
      ));
    }
  }

  void _onCategoryChanged(
    TravelCategoryChanged event,
    Emitter<TravelState> emit,
  ) {
    // Client-side filter — no new network call needed.
    emit(state.copyWith(selectedCategory: event.category));
  }

  void _onSearchChanged(
    TravelSearchChanged event,
    Emitter<TravelState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  // ── Package Detail ─────────────────────────────────────────────────────────

  Future<void> _onDetailRequested(
    TravelPackageDetailRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(
      detailStatus: TravelStatus.loading,
      selectedPackage: null,
    ));
    try {
      final pkg = await _service.getPackageDetails(event.packageId);
      if (pkg != null) {
        emit(state.copyWith(
          detailStatus: TravelStatus.success,
          selectedPackage: pkg,
        ));
      } else {
        emit(state.copyWith(
          detailStatus: TravelStatus.failure,
          detailError: 'Package not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        detailStatus: TravelStatus.failure,
        detailError: e.toString(),
      ));
    }
  }

  // ── Guide: My Packages ─────────────────────────────────────────────────────

  Future<void> _onMyPackagesRequested(
    TravelMyPackagesRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(myPackagesStatus: TravelStatus.loading));
    try {
      final packages = await _service.getMyPackages();
      emit(state.copyWith(
        myPackagesStatus: TravelStatus.success,
        myPackages: packages,
      ));
    } catch (e) {
      emit(state.copyWith(myPackagesStatus: TravelStatus.failure));
    }
  }

  // ── User: Bookings ─────────────────────────────────────────────────────────

  Future<void> _onMyBookingsRequested(
    TravelMyBookingsRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(bookingsStatus: TravelStatus.loading));
    try {
      final bookings = await _service.getMyBookings();
      emit(state.copyWith(
        bookingsStatus: TravelStatus.success,
        myBookings: bookings,
      ));
    } catch (e) {
      emit(state.copyWith(
        bookingsStatus: TravelStatus.failure,
        bookingsError: e.toString(),
      ));
    }
  }

  // ── Join / Cancel ──────────────────────────────────────────────────────────

  Future<void> _onJoinRequested(
    TravelJoinRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final booking = await _service.joinPackage(
        packageId: event.packageId,
        travelers: event.travelers,
        contactNumber: event.contactNumber,
        notes: event.notes,
      );
      if (booking != null) {
        emit(state.copyWith(
          actionStatus: BookingActionStatus.success,
          actionSuccessMessage: 'You have successfully joined the trip! 🎉',
          myBookings: [...state.myBookings, booking],
        ));
      } else {
        emit(state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: 'Failed to join package. Please try again.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        actionStatus: BookingActionStatus.failure,
        actionError: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onCancelBookingRequested(
    TravelCancelBookingRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final success = await _service.cancelBooking(event.bookingId);
      if (success) {
        final updated = state.myBookings.map((b) {
          return b.id == event.bookingId
              ? BookingModel.fromJson({'_id': b.id, 'status': 'Cancelled', 'paymentStatus': b.paymentStatus, 'totalAmount': b.totalAmount, 'contactNumber': b.contactNumber, 'bookingDate': b.bookingDate.toIso8601String()})
              : b;
        }).toList();
        emit(state.copyWith(
          actionStatus: BookingActionStatus.success,
          actionSuccessMessage: 'Booking cancelled successfully.',
          myBookings: updated,
        ));
      } else {
        throw Exception('Failed to cancel booking');
      }
    } catch (e) {
      emit(state.copyWith(
        actionStatus: BookingActionStatus.failure,
        actionError: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onStatusReset(TravelStatusReset event, Emitter<TravelState> emit) {
    emit(state.copyWith(
      actionStatus: BookingActionStatus.idle,
      actionError: null,
      actionSuccessMessage: null,
    ));
  }
}


