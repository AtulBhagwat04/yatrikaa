import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/places_service.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
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
    emit(state.copyWith(status: PlaceDetailsStatus.loading));
    try {
      final place = await _placesService.getPlaceDetails(event.placeId);

      if (place != null) {
        // Calculate distance from user location
        double? distanceKm;
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }

            if (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always) {
              // Try getting last known position first for speed
              Position? position = await Geolocator.getLastKnownPosition();

              // If no last known position, fetch current with timeout
              position ??= await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 5),
              );

              final distanceMeters = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                place.lat,
                place.lng,
              );
              distanceKm = distanceMeters / 1000;
            }
          }
        } catch (e) {
          print("Error calculating distance: $e");
          // Continue without distance
        }

        // Also fetch nearby places as requested in REQUIREMENTS
        List<PlaceModel> nearby = await _placesService.getNearbyPlaces(
          place.lat,
          place.lng,
        );

        // If we have a user position (distanceKm calculated for main place),
        // we likely have the position to calculate distances for nearby places too.
        if (distanceKm != null) {
          try {
            // We need the position again, but since we are in the same scope and
            // calculated distanceKm successfully, we can assume position *was* fetched.
            // However, `position` variable scope was limited to the try block above.
            // Let's refactor slightly to reuse the position if available.
            // But for now, to avoid massive refactor, let's just grab getLastKnownPosition again (should be instant)
            Position? position = await Geolocator.getLastKnownPosition();

            if (position != null) {
              // First filter out irrelevant places
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
          } catch (e) {
            print("Error calculating nearby distances: $e");
          }
        }

        // Create updated place with distance and nearby places
        final detailedPlace = place.copyWith(
          nearbyPlaces: nearby,
          distance: distanceKm,
        );

        emit(
          state.copyWith(
            status: PlaceDetailsStatus.success,
            place: detailedPlace,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: PlaceDetailsStatus.failure,
            errorMessage: AppStrings.errPlaceDetails,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PlaceDetailsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onFavoriteToggled(
    PlaceDetailsFavoriteToggled event,
    Emitter<PlaceDetailsState> emit,
  ) {
    emit(state.copyWith(isFavorite: !state.isFavorite));
  }
}
