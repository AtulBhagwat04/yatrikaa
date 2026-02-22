import 'dart:async';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/places_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PlacesService _placesService = PlacesService();
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;

  HomeBloc() : super(const HomeState()) {
    on<HomeStarted>(_onHomeStarted);
    on<HomeLocationRefreshRequested>(_onLocationRefreshRequested);
    on<HomeLocationUpdated>(_onLocationUpdated);
    on<HomeCategoryChanged>(_onCategoryChanged);
    on<HomeTabChanged>(_onTabChanged);
  }

  Future<void> _onHomeStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    // Always load popular places first (no location needed)
    await _fetchPopularPlaces(emit);
    if (isClosed) return;

    bool permissionGranted = await _handlePermission(emit);
    if (isClosed) return;

    if (permissionGranted) {
      await _getCurrentLocation(emit);
      if (isClosed) return;
      _startLocationTracking();
    }
  }

  Future<void> _onLocationRefreshRequested(
    HomeLocationRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _getCurrentLocation(emit);
  }

  Future<void> _onLocationUpdated(
    HomeLocationUpdated event,
    Emitter<HomeState> emit,
  ) async {
    await _updateLocationState(event.position, emit);
  }

  Future<void> _onCategoryChanged(
    HomeCategoryChanged event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        isLoadingRecommended: true,
      ),
    );

    try {
      // 1. Try DB first for category-specific popular places
      // Normalize category (e.g. "Forts" -> "Fort") for better DB regex matching
      final normalizedCat = _normalizeCategory(event.category);

      List<PlaceModel> places = await _placesService.getFamousMaharashtraPlaces(
        category: normalizedCat,
      );

      // 2. If DB has no/few results, fallback to premium Google search
      // We now fallback even for 'All' if DB is thin
      if (places.length < 3) {
        final searchQuery = (event.category == AppStrings.catAll)
            ? AppStrings.pdDiscoveryQuery
            : (ApiConstants.categoryQueries[event.category] ??
                  "${event.category} in Maharashtra");

        places = await _placesService.searchPlaces(
          searchQuery,
          null, // No location bias for global "Popular" category results
          null,
        );
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            recommendedPlaces: places,
            isLoadingRecommended: false,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingRecommended: false));
      }
    }
  }

  String _normalizeCategory(String cat) {
    if (cat == AppStrings.catAll) return cat;
    if (cat == 'Forts') return 'Fort';
    if (cat == 'Beaches') return 'Beach';
    if (cat == 'Temples') return 'Temple';
    if (cat == 'Caves') return 'Cave';
    if (cat == 'Waterfalls') return 'Waterfall';
    if (cat == 'Museums') return 'Museum';
    if (cat == 'Lakes') return 'Lake';
    if (cat == 'UNESCO Sites') return 'UNESCO';
    return cat;
  }

  void _onTabChanged(HomeTabChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedIndex: event.index));
  }

  Future<bool> _handlePermission(Emitter<HomeState> emit) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (isClosed) return false;

      if (!serviceEnabled) {
        emit(
          state.copyWith(
            currentLocation: AppStrings.turnOnGps,
            isLoadingLocation: false,
          ),
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (isClosed) return false;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (isClosed) return false;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(
          state.copyWith(
            currentLocation: AppStrings.permissionNeeded,
            isLoadingLocation: false,
          ),
        );
        return false;
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            currentLocation: AppStrings.error,
            isLoadingLocation: false,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _getCurrentLocation(Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoadingLocation: true));
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!isClosed) {
        await _updateLocationState(position, emit);
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingLocation: false));
      }
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 500,
    );

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (isClosed) return;
            if (_currentPosition != null) {
              double distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                position.latitude,
                position.longitude,
              );
              if (distance < 500) return;
            }
            add(HomeLocationUpdated(position));
          },
        );
  }

  Future<void> _updateLocationState(
    Position position,
    Emitter<HomeState> emit,
  ) async {
    _currentPosition = position;
    String locationText =
        "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        locationText =
            "${place.locality ?? ""}, ${place.administrativeArea ?? ""}";
      }
    } catch (_) {}

    if (!isClosed) {
      emit(
        state.copyWith(
          currentLocation: locationText,
          isLoadingLocation: false,
          status: HomeStatus.success,
        ),
      );

      await _fetchAllData(emit);
    }
  }

  Future<void> _fetchPopularPlaces(Emitter<HomeState> emit) async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingRecommended: true));
    try {
      // 1. Try DB first
      final normalizedCat = _normalizeCategory(state.selectedCategory);
      List<PlaceModel> places = await _placesService.getFamousMaharashtraPlaces(
        category: normalizedCat,
      );

      // 2. Fallback to Search if DB is empty for category (even for 'All')
      if (places.length < 3) {
        final searchQuery = (state.selectedCategory == AppStrings.catAll)
            ? AppStrings.pdDiscoveryQuery
            : (ApiConstants.categoryQueries[state.selectedCategory] ??
                  "${state.selectedCategory} in Maharashtra");

        places = await _placesService.searchPlaces(searchQuery, null, null);
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            recommendedPlaces: places,
            isLoadingRecommended: false,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isLoadingRecommended: false));
    }
  }

  Future<void> _fetchAllData(Emitter<HomeState> emit) async {
    if (isClosed) return;

    // Nearby places require location
    if (_currentPosition == null) return;

    emit(state.copyWith(isLoadingNearby: true));

    try {
      final nearbyPlaces = await _placesService.getNearbyPlaces(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (!isClosed) {
        emit(
          state.copyWith(nearbyPlaces: nearbyPlaces, isLoadingNearby: false),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(isLoadingNearby: false, errorMessage: e.toString()),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
  }
}
