import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/core/services/places_service.dart';
import 'package:yatrikaa/Frontend/core/services/events_service.dart';
import 'package:yatrikaa/Frontend/core/models/event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_event.dart';
import 'package:yatrikaa/Frontend/views/screens/home/bloc/home_state.dart';
import 'package:yatrikaa/Frontend/core/utils/app_cache.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PlacesService _placesService = PlacesService();
  final EventsService _eventsService = EventsService();
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Position? _currentPosition;

  HomeBloc() : super(const HomeState()) {
    on<HomeStarted>(_onHomeStarted);
    on<HomeLoadCache>(_onLoadCache);
    on<HomeConnectivityChanged>(_onConnectivityChanged);
    on<HomeLocationServiceStatusChanged>(_onLocationServiceStatusChanged);
    on<HomeLocationRefreshRequested>(_onLocationRefreshRequested);
    on<HomeLocationUpdated>(_onLocationUpdated);
    on<HomeCategoryChanged>(_onCategoryChanged);
    on<HomeTabChanged>(_onTabChanged);
    on<HomeEventUpdateEvent>(_onEventUpdated);
    on<HomeSearchRequested>(_onSearchRequested);
    on<HomeSearchCleared>(_onSearchCleared);
  }

  // ── Connectivity & Listeners ──────────────────────────────────────────────

  void _setupListeners() {
    // 1. Connectivity listener
    _connectivitySubscription?.cancel();

    // Initial check (with slight delay to ensure plugin is ready)
    Future.delayed(const Duration(milliseconds: 500), () async {
      final results = await Connectivity().checkConnectivity();
      await _handleConnectivityChange(results);
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _handleConnectivityChange(results);
    });

    // 2. Location Service status listener
    _serviceStatusSubscription?.cancel();

    // Initial check for location
    Geolocator.isLocationServiceEnabled().then((enabled) {
      add(HomeLocationServiceStatusChanged(enabled));
    });

    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      status,
    ) {
      add(HomeLocationServiceStatusChanged(status == ServiceStatus.enabled));
    });
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    final hasInterface =
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (!hasInterface) {
      add(const HomeConnectivityChanged(true));
      return;
    }

    // Even if interface is up, check if we can actually reach the internet
    final hasInternet = await _checkRealInternet();
    add(HomeConnectivityChanged(!hasInternet));
  }

  Future<bool> _checkRealInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _onConnectivityChanged(
    HomeConnectivityChanged event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('Connectivity Changed: isOffline = ${event.isOffline}');

    // Only update and fetch if the status actually changed
    if (state.isOffline == event.isOffline) return;

    emit(state.copyWith(isOffline: event.isOffline));

    if (!event.isOffline) {
      // If we just came online, trigger a fresh load
      // We await these so that the 'emit' object remains valid throughout the async calls
      await Future.wait([_fetchPopularPlaces(emit), _fetchPopularEvents(emit)]);
    }
  }

  void _onLocationServiceStatusChanged(
    HomeLocationServiceStatusChanged event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isLocationEnabled: event.isEnabled));
    if (event.isEnabled) {
      add(HomeLocationRefreshRequested());
    }
  }

  // ── Home Logic ─────────────────────────────────────────────────────────────

  Future<void> _onLoadCache(
    HomeLoadCache event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final cachedData = await AppCache.getCachedHomeData();

      if (isClosed) return;

      final recommended = List<PlaceModel>.from(
        cachedData['recommended'] ?? [],
      );
      final nearby = List<PlaceModel>.from(cachedData['nearby'] ?? []);
      final events = List<EventModel>.from(cachedData['events'] ?? []);
      final location = cachedData['location'] as String?;

      if (recommended.isNotEmpty || nearby.isNotEmpty || events.isNotEmpty) {
        emit(
          state.copyWith(
            recommendedPlaces: recommended,
            nearbyPlaces: nearby,
            popularEvents: events,
            currentLocation: location ?? state.currentLocation,
            // Keep loading flags ACTIVE — fresh fetch is already running in
            // parallel. The UI will stay in its loading/shimmer state and
            // only settle once the network response comes back.
            // This prevents the jarring flash: stale data → real data.
            isLoadingLocation: location == null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading home cache: $e');
    }
  }

  Future<void> _onHomeStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    // 1. Setup listeners for real-time monitoring
    _setupListeners();

    // 2. Load from cache immediately
    add(HomeLoadCache());

    // 3. Start fetching fresh data in parallel
    final List<Future> initialTasks = [
      _fetchPopularPlaces(emit),
      _fetchPopularEvents(emit),
    ];

    await Future.wait(initialTasks);
    if (isClosed) return;

    bool permissionGranted = await _handlePermission(emit);
    if (isClosed) return;

    if (permissionGranted) {
      add(HomeLocationRefreshRequested());
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
      final normalizedCat = _normalizeCategory(event.category);
      List<PlaceModel> places = await _placesService.getFamousMaharashtraPlaces(
        category: normalizedCat,
      );

      if (places.length < 5) {
        final searchQuery = (event.category == AppStrings.catAll)
            ? AppStrings.pdDiscoveryQuery
            : (ApiConstants.categoryQueries[event.category] ??
                  "${event.category} in Maharashtra");

        final googlePlaces = await _placesService.searchPlaces(
          searchQuery,
        );

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
            isLocationEnabled: false,
          ),
        );
        return false;
      }

      emit(state.copyWith(isLocationEnabled: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _getCurrentLocation(Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoadingLocation: true));
    try {
      // Ensure we have permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(
          state.copyWith(
            isLoadingLocation: false,
            currentLocation: "Permission Denied",
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!isClosed) {
        await _updateLocationState(position, emit);
        _startLocationTracking();
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
      await AppCache.saveHomeData(location: locationText);
      await _fetchAllData(emit);
    }
  }

  Future<void> _fetchPopularEvents(Emitter<HomeState> emit) async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingEvents: true));
    try {
      List<EventModel> events = await _eventsService.getEvents();
      events.sort((a, b) => a.date.compareTo(b.date));

      if (!isClosed && events.isNotEmpty) {
        emit(state.copyWith(popularEvents: events, isLoadingEvents: false));
        await AppCache.saveHomeData(events: events);
      } else if (!isClosed) {
        emit(state.copyWith(isLoadingEvents: false));
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
      final normalizedCat = _normalizeCategory(state.selectedCategory);
      List<PlaceModel> places = await _placesService.getFamousMaharashtraPlaces(
        category: normalizedCat,
      );

      if (places.length < 5) {
        final searchQuery = (state.selectedCategory == AppStrings.catAll)
            ? AppStrings.pdDiscoveryQuery
            : (ApiConstants.categoryQueries[state.selectedCategory] ??
                  "${state.selectedCategory} in Maharashtra");

        final googlePlaces = await _placesService.searchPlaces(
          searchQuery,
        );

        final existingIds = places.map((p) => p.id).toSet();
        for (var p in googlePlaces) {
          if (!existingIds.contains(p.id)) {
            places.add(p);
          }
        }
      }
      if (!isClosed && places.isNotEmpty) {
        emit(
          state.copyWith(
            recommendedPlaces: places,
            isLoadingRecommended: false,
          ),
        );
        await AppCache.saveHomeData(recommended: places);
      } else if (!isClosed) {
        emit(state.copyWith(isLoadingRecommended: false));
      }
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isLoadingRecommended: false));
    }
  }

  Future<void> _fetchAllData(Emitter<HomeState> emit) async {
    if (isClosed) return;
    if (_currentPosition == null) return;

    emit(state.copyWith(isLoadingNearby: true));

    try {
      final nearbyPlaces = await _placesService.getNearbyPlaces(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (!isClosed && nearbyPlaces.isNotEmpty) {
        emit(
          state.copyWith(nearbyPlaces: nearbyPlaces, isLoadingNearby: false),
        );
        await AppCache.saveHomeData(nearby: nearbyPlaces);
      } else if (!isClosed) {
        emit(state.copyWith(isLoadingNearby: false));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingNearby: false));
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

  Future<void> _onSearchRequested(
    HomeSearchRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(HomeSearchCleared());
      return;
    }

    emit(
      state.copyWith(
        isSearching: true,
        searchQuery: event.query,
        isLoadingSearch: true,
      ),
    );

    try {
      final results = await _placesService.searchPlaces(
        event.query,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      );

      if (!isClosed) {
        emit(state.copyWith(searchResults: results, isLoadingSearch: false));
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(isLoadingSearch: false, errorMessage: e.toString()),
        );
      }
    }
  }

  void _onSearchCleared(HomeSearchCleared event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        isSearching: false,
        searchQuery: "",
        searchResults: const [],
        isLoadingSearch: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    return super.close();
  }
}
