import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/services/packages_service.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:yatrikaa/Frontend/core/utils/app_cache.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';

class TravelBloc extends Bloc<TravelEvent, TravelState> {
  final PackagesService _service = PackagesService();

  TravelBloc() : super(const TravelState()) {
    on<TravelLoadCache>(_onLoadCache);
    on<TravelPackagesRequested>(_onPackagesRequested);
    on<TravelCategoryChanged>(_onCategoryChanged);
    on<TravelSearchChanged>(_onSearchChanged);
    on<TravelPackageDetailRequested>(_onPackageDetailRequested);
    on<TravelMyPackagesRequested>(_onMyPackagesRequested);
    on<TravelMyBookingsRequested>(_onMyBookingsRequested);
    on<TravelJoinRequested>(_onJoinRequested);
    on<TravelCancelBookingRequested>(_onCancelBookingRequested);
    on<TravelAdminReviewRequested>(_onAdminReviewRequested);
    on<TravelPublishPackageRequested>(_onPublishPackageRequested);
    on<TravelGuideRequestsRequested>(_onGuideRequestsRequested);
    on<TravelHandleGuideRequested>(_onHandleGuideRequested);
    on<TravelDeletePackageRequested>(_onDeletePackageRequested);
    on<TravelUpdatePackageRequested>(_onUpdatePackageRequested);
    on<TravelCreatePackageRequested>(_onCreatePackageRequested);
    on<TravelPackageParticipantsRequested>(_onPackageParticipantsRequested);
    on<TravelAllGuideBookingsRequested>(_onAllGuideBookingsRequested);
    on<TravelHandleBookingRequested>(_onHandleBookingRequested);
    on<TravelStatusReset>(_onStatusReset);
  }

  Future<void> _onLoadCache(
    TravelLoadCache event,
    Emitter<TravelState> emit,
  ) async {
    try {
      final cached = await AppCache.getRawData(AppCache.keyPackages);
      if (cached.isNotEmpty) {
        final pkgs = cached.map((j) => TravelPackageModel.fromJson(j)).toList();
        emit(
          state.copyWith(packages: pkgs, packagesStatus: TravelStatus.success),
        );
      }
    } catch (e) {
      print('TravelBloc._onLoadCache error: $e');
    }
  }

  Future<void> _onPackagesRequested(
    TravelPackagesRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(packagesStatus: TravelStatus.loading));
    try {
      final packages = await _service.getPackages(
        category: event.category,
        search: event.search,
      );
      emit(
        state.copyWith(
          packagesStatus: TravelStatus.success,
          packages: packages,
          selectedCategory: event.category,
          searchQuery: event.search,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          packagesStatus: TravelStatus.failure,
          packagesError: e.toString(),
        ),
      );
    }
  }

  void _onCategoryChanged(
    TravelCategoryChanged event,
    Emitter<TravelState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  void _onSearchChanged(TravelSearchChanged event, Emitter<TravelState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onPackageDetailRequested(
    TravelPackageDetailRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(detailStatus: TravelStatus.loading));
    try {
      final pkg = await _service.getPackageDetails(event.packageId);
      if (pkg != null) {
        emit(
          state.copyWith(
            detailStatus: TravelStatus.success,
            selectedPackage: pkg,
          ),
        );
      } else {
        emit(
          state.copyWith(
            detailStatus: TravelStatus.failure,
            detailError: 'Package not found',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          detailStatus: TravelStatus.failure,
          detailError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onMyPackagesRequested(
    TravelMyPackagesRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(myPackagesStatus: TravelStatus.loading));
    try {
      final packages = await _service.getMyPackages();
      emit(
        state.copyWith(
          myPackagesStatus: TravelStatus.success,
          myPackages: packages,
        ),
      );
    } catch (e) {
      emit(state.copyWith(myPackagesStatus: TravelStatus.failure));
    }
  }

  Future<void> _onMyBookingsRequested(
    TravelMyBookingsRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(bookingsStatus: TravelStatus.loading));
    try {
      final bookings = await _service.getMyBookings();
      emit(
        state.copyWith(
          bookingsStatus: TravelStatus.success,
          myBookings: bookings,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          bookingsStatus: TravelStatus.failure,
          bookingsError: e.toString(),
        ),
      );
    }
  }

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
        emit(
          state.copyWith(
            actionStatus: BookingActionStatus.success,
            actionSuccessMessage: 'Booking request sent successfully! 🎉',
          ),
        );
      } else {
        throw Exception('Failed to join package');
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCancelBookingRequested(
    TravelCancelBookingRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final message = await _service.cancelBooking(event.bookingId);
      // Refresh bookings
      final bookings = await _service.getMyBookings();
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.success,
          actionSuccessMessage: message,
          myBookings: bookings,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onStatusReset(
    TravelStatusReset event,
    Emitter<TravelState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: BookingActionStatus.idle,
        actionError: null,
        actionSuccessMessage: null,
      ),
    );
    return Future.value();
  }

  Future<void> _onAdminReviewRequested(
    TravelAdminReviewRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(adminPackagesStatus: TravelStatus.loading));
    try {
      final packages = await _service.getAdminPackages(status: event.status);
      emit(
        state.copyWith(
          adminPackagesStatus: TravelStatus.success,
          adminPackages: packages,
        ),
      );
    } catch (e) {
      emit(state.copyWith(adminPackagesStatus: TravelStatus.failure));
    }
  }

  Future<void> _onPublishPackageRequested(
    TravelPublishPackageRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final success = await _service.publishPackage(event.packageId);
      if (success) {
        final updated = state.adminPackages.map((p) {
          if (p.id == event.packageId) {
            return p.copyWith(status: 'Published');
          }
          return p;
        }).toList();

        emit(
          state.copyWith(
            actionStatus: BookingActionStatus.success,
            actionSuccessMessage: 'Package published and is now live! 🚀',
            adminPackages: updated,
          ),
        );
      } else {
        throw Exception('Failed to publish package');
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onGuideRequestsRequested(
    TravelGuideRequestsRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(adminGuideRequestsStatus: TravelStatus.loading));
    try {
      final requests = await _service.getGuideRequests();
      emit(
        state.copyWith(
          adminGuideRequestsStatus: TravelStatus.success,
          adminGuideRequests: requests,
        ),
      );
    } catch (e) {
      emit(state.copyWith(adminGuideRequestsStatus: TravelStatus.failure));
    }
  }

  Future<void> _onHandleGuideRequested(
    TravelHandleGuideRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final success = await _service.handleGuideRequest(
        event.userId,
        event.action,
      );
      if (success) {
        final updated = state.adminGuideRequests
            .where((r) => r.userId != event.userId)
            .toList();

        emit(
          state.copyWith(
            actionStatus: BookingActionStatus.success,
            actionSuccessMessage:
                'Guide request ${event.action}d successfully!',
            adminGuideRequests: updated,
          ),
        );
      } else {
        throw Exception('Failed to handle guide request');
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeletePackageRequested(
    TravelDeletePackageRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final success = await _service.deletePackage(event.packageId);
      if (success) {
        final updated = state.myPackages
            .where((p) => p.id != event.packageId)
            .toList();
        emit(
          state.copyWith(
            actionStatus: BookingActionStatus.success,
            actionSuccessMessage: 'Package deleted successfully.',
            myPackages: updated,
          ),
        );
      } else {
        throw Exception('Failed to delete package');
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdatePackageRequested(
    TravelUpdatePackageRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final success = await _service.updatePackage(
        event.packageId,
        event.body,
        imageFiles: event.imageFiles,
      );
      if (success) {
        // Refresh my packages list
        final packages = await _service.getMyPackages();
        emit(
          state.copyWith(
            actionStatus: BookingActionStatus.success,
            actionSuccessMessage: 'Package updated successfully! ✨',
            myPackages: packages,
          ),
        );
      } else {
        throw Exception('Failed to update package');
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreatePackageRequested(
    TravelCreatePackageRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final success = await _service.createPackage(
        event.body,
        imageFiles: event.imageFiles,
      );
      if (success) {
        // Refresh my packages list
        final packages = await _service.getMyPackages();
        emit(
          state.copyWith(
            actionStatus: BookingActionStatus.success,
            actionSuccessMessage:
                'Package created! It will go live after review. 🎉',
            myPackages: packages,
          ),
        );
      } else {
        throw Exception('Failed to create package');
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onPackageParticipantsRequested(
    TravelPackageParticipantsRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(guideBookingsStatus: TravelStatus.loading));
    try {
      final bookings = await _service.getPackageParticipants(event.packageId);
      emit(
        state.copyWith(
          guideBookingsStatus: TravelStatus.success,
          guideBookings: bookings,
        ),
      );
    } catch (e) {
      emit(state.copyWith(guideBookingsStatus: TravelStatus.failure));
    }
  }

  Future<void> _onAllGuideBookingsRequested(
    TravelAllGuideBookingsRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(guideBookingsStatus: TravelStatus.loading));
    try {
      final bookings = await _service.getGuideAllBookings();
      emit(
        state.copyWith(
          guideBookingsStatus: TravelStatus.success,
          guideBookings: bookings,
        ),
      );
    } catch (e) {
      emit(state.copyWith(guideBookingsStatus: TravelStatus.failure));
    }
  }

  Future<void> _onHandleBookingRequested(
    TravelHandleBookingRequested event,
    Emitter<TravelState> emit,
  ) async {
    emit(state.copyWith(actionStatus: BookingActionStatus.loading));
    try {
      final success = await _service.handleBooking(
        event.bookingId,
        event.action,
      );
      if (success) {
        emit(
          state.copyWith(
            actionStatus: BookingActionStatus.success,
            actionSuccessMessage: 'Booking status updated to ${event.action}',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: BookingActionStatus.failure,
          actionError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
