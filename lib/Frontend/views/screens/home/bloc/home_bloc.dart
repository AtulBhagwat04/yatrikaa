import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/places_service.dart';
import 'package:bhatkanti_app/Frontend/core/services/events_service.dart';
import 'package:bhatkanti_app/Frontend/core/models/event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PlacesService _placesService = PlacesService();
  final EventsService _eventsService = EventsService();
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;

  HomeBloc() : super(const HomeState()) {
    on<HomeStarted>(_onHomeStarted);
    on<HomeLocationRefreshRequested>(_onLocationRefreshRequested);
    on<HomeLocationUpdated>(_onLocationUpdated);
    on<HomeCategoryChanged>(_onCategoryChanged);
    on<HomeTabChanged>(_onTabChanged);
    on<HomeEventUpdateEvent>(_onEventUpdated);
  }

  Future<void> _onHomeStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    // Always load popular places and events (no location needed)
    await Future.wait([_fetchPopularPlaces(emit), _fetchPopularEvents(emit)]);
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

      // 2. Supplement with premium Google search if DB results are few
      if (places.length < 5) {
        final searchQuery = (event.category == AppStrings.catAll)
            ? AppStrings.pdDiscoveryQuery
            : (ApiConstants.categoryQueries[event.category] ??
                  "${event.category} in Maharashtra");

        final googlePlaces = await _placesService.searchPlaces(
          searchQuery,
          null,
          null,
        );
        
        // Combine results, ensuring DB places are at the top
        final existingIds = places.map((p) => p.id).toSet();
        for (var p in googlePlaces) {
          if (!existingIds.contains(p.id)) {
            places.add(p);
          }
        }
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

  Future<void> _fetchPopularEvents(Emitter<HomeState> emit) async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingEvents: true));
    try {
      // Fetch all upcoming events to ensure they show up on home even if not marked popular
      List<EventModel> events = await _eventsService.getEvents();
      
      // If we have many, we could prioritize popular ones or just show all
      // For now, sorting by date is best
      events.sort((a, b) => a.date.compareTo(b.date));

      if (!isClosed) {
        emit(state.copyWith(popularEvents: events, isLoadingEvents: false));
      }
    } catch (e) {
      debugPrint('Error in _fetchPopularEvents: $e');
      if (!isClosed) emit(state.copyWith(isLoadingEvents: false));
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

      // 2. Supplement with Search if DB is empty/low for category
      if (places.length < 5) {
        final searchQuery = (state.selectedCategory == AppStrings.catAll)
            ? AppStrings.pdDiscoveryQuery
            : (ApiConstants.categoryQueries[state.selectedCategory] ??
                  "${state.selectedCategory} in Maharashtra");

        final googlePlaces = await _placesService.searchPlaces(searchQuery, null, null);
        
        // Combine results, ensuring DB places are at the top
        final existingIds = places.map((p) => p.id).toSet();
        for (var p in googlePlaces) {
          if (!existingIds.contains(p.id)) {
            places.add(p);
          }
        }
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

  void _onEventUpdated(HomeEventUpdateEvent event, Emitter<HomeState> emit) {
    if (isClosed) return;

    final updatedEvents = state.popularEvents.map((e) {
      return e.id == event.event.id ? event.event : e;
    }).toList();

    emit(state.copyWith(popularEvents: updatedEvents));
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
  }
}
