import 'dart:async';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/services/places_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'home_event.dart';
import 'home_state.dart';

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
      final places = event.category == AppStrings.catAll
          ? await _placesService.getFamousMaharashtraPlaces()
          : await _placesService.searchPlaces(
              "${event.category} in Maharashtra",
              _currentPosition?.latitude,
              _currentPosition?.longitude,
            );

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

  Future<void> _fetchAllData(Emitter<HomeState> emit) async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingRecommended: true, isLoadingNearby: true));

    try {
      final recommendedTask = state.selectedCategory == AppStrings.catAll
          ? _placesService.getFamousMaharashtraPlaces()
          : _placesService.searchPlaces(
              "${state.selectedCategory} in Maharashtra",
              _currentPosition?.latitude,
              _currentPosition?.longitude,
            );

      if (_currentPosition == null) return;

      final nearbyTask = _placesService.getNearbyPlaces(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final results = await Future.wait([recommendedTask, nearbyTask]);

      if (!isClosed) {
        emit(
          state.copyWith(
            recommendedPlaces: results[0],
            nearbyPlaces: results[1],
            isLoadingRecommended: false,
            isLoadingNearby: false,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingRecommended: false,
            isLoadingNearby: false,
            errorMessage: e.toString(),
          ),
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
