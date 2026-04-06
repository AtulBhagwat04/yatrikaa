import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/places_service.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'place_details_event.dart';
import 'place_details_state.dart';

class PlaceDetailsBloc extends Bloc<PlaceDetailsEvent, PlaceDetailsState> {
  final PlacesService _placesService = PlacesService();

  PlaceDetailsBloc() : super(const PlaceDetailsState()) {
    on<PlaceDetailsStarted>(_onStarted);
    on<PlaceDetailsFavoriteToggled>(_onFavoriteToggled);
    on<PlaceDetailsBookmarkToggled>(_onBookmarkToggled);
  }

  void _onBookmarkToggled(
    PlaceDetailsBookmarkToggled event,
    Emitter<PlaceDetailsState> emit,
  ) {
    emit(state.copyWith(isBookmarked: !state.isBookmarked));
  }

  Future<void> _onStarted(
    PlaceDetailsStarted event,
    Emitter<PlaceDetailsState> emit,
  ) async {
    // 1. Show initial data immediately if available
    if (event.initialPlace != null) {
      emit(state.copyWith(
        status: PlaceDetailsStatus.success,
        place: event.initialPlace,
      ));
    } else {
      emit(state.copyWith(status: PlaceDetailsStatus.loading));
    }

    try {
      // 2. Fetch Details & Favorite status in parallel
      final results = await Future.wait([
        _placesService.getPlaceDetails(event.placeId),
        _placesService.checkIfFavorite(event.placeId),
      ]);

      final place = results[0] as PlaceModel?;
      final isFavorite = results[1] as bool;

      if (place != null) {
        // Emit details immediately before fetching nearby/distance for better responsiveness
        emit(
          state.copyWith(
            status: PlaceDetailsStatus.success,
            place: place,
            isFavorite: isFavorite,
          ),
        );

        // 3. Fetch Nearby & User Position in parallel (Non-blocking for core details)
        final resultsBackground = await Future.wait([
          _placesService.getNearbyPlaces(place.lat, place.lng),
          _getUserPosition(),
        ]);

        List<PlaceModel> nearby = resultsBackground[0] as List<PlaceModel>;
        final Position? position = resultsBackground[1] as Position?;

        double? distanceKm;
        if (position != null) {
          final distanceMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            place.lat,
            place.lng,
          );
          distanceKm = distanceMeters / 1000;

          // Calculate distances for nearby places
          nearby = nearby
              .where((p) {
                final name = p.name.toLowerCase();
                final type = p.category?.toLowerCase() ?? "";
                return !name.contains("hospital") &&
                    !name.contains("school") &&
                    !name.contains("college") &&
                    !name.contains("cafe") &&
                    !name.contains("atm") &&
                    !name.contains("bank") &&
                    !name.contains("gym") &&
                    !name.contains("pharmacy") &&
                    !name.contains("clinic") &&
                    !name.contains("store") &&
                    !type.contains("health") &&
                    !type.contains("school") &&
                    !type.contains("finance");
              })
              .map((nearbyPlace) {
                final distMeters = Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  nearbyPlace.lat,
                  nearbyPlace.lng,
                );
                return nearbyPlace.copyWith(distance: distMeters / 1000);
              })
              .toList();
        }

        // 4. Update with final background data
        emit(
          state.copyWith(
            place: place.copyWith(
              nearbyPlaces: nearby,
              distance: distanceKm,
            ),
          ),
        );
      } else {
        if (state.place == null) {
          emit(
            state.copyWith(
              status: PlaceDetailsStatus.failure,
              errorMessage: AppStrings.errPlaceDetails,
            ),
          );
        }
      }
    } catch (e) {
      if (state.place == null) {
        emit(
          state.copyWith(
            status: PlaceDetailsStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  /// Helper to get user position with minimal delay
  Future<Position?> _getUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Fast path: getLastKnownPosition
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) return position;

      // Slow path: getCurrentPosition (shorter timeout for UI performance)
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _onFavoriteToggled(
    PlaceDetailsFavoriteToggled event,
    Emitter<PlaceDetailsState> emit,
  ) async {
    final newStatus = !state.isFavorite;
    emit(state.copyWith(isFavorite: newStatus));

    if (state.place != null) {
      try {
        final result = await _placesService.toggleFavorite(
          state.place!.id,
          place: state.place,
        );
        final isNowFavorite = result['isFavorite'] ?? newStatus;
        emit(
          state.copyWith(
            isFavorite: isNowFavorite,
            toastMessage: isNowFavorite
                ? "Added to Liked Places"
                : "Removed from Liked Places",
          ),
        );
      } catch (e) {
        // Rollback on failure
        emit(
          state.copyWith(
            isFavorite: !newStatus,
            toastMessage: "Error updating favorites",
          ),
        );
      }
    }
  }
}
