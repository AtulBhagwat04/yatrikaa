import 'package:equatable/equatable.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/core/models/event_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final String currentLocation;
  final bool isLoadingLocation;
  final String selectedCategory;
  final int selectedIndex;

  final List<PlaceModel> recommendedPlaces;
  final List<PlaceModel> nearbyPlaces;
  final List<EventModel> popularEvents;

  final List<PlaceModel> searchResults;
  final bool isSearching;
  final String searchQuery;

  final bool isLoadingRecommended;
  final bool isLoadingNearby;
  final bool isLoadingEvents;
  final bool isLoadingSearch;
  final bool isOffline;
  final bool isLocationEnabled;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.currentLocation = "Fetching location...",
    this.isLoadingLocation = true,
    this.selectedCategory = "All",
    this.selectedIndex = 0,
    this.recommendedPlaces = const <PlaceModel>[],
    this.nearbyPlaces = const <PlaceModel>[],
    this.popularEvents = const <EventModel>[],
    this.searchResults = const <PlaceModel>[],
    this.isSearching = false,
    this.searchQuery = "",
    this.isLoadingRecommended = true,
    this.isLoadingNearby = true,
    this.isLoadingEvents = true,
    this.isLoadingSearch = false,
    this.isOffline = false,
    this.isLocationEnabled = true,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? currentLocation,
    bool? isLoadingLocation,
    String? selectedCategory,
    int? selectedIndex,
    List<PlaceModel>? recommendedPlaces,
    List<PlaceModel>? nearbyPlaces,
    List<EventModel>? popularEvents,
    List<PlaceModel>? searchResults,
    bool? isSearching,
    String? searchQuery,
    bool? isLoadingRecommended,
    bool? isLoadingNearby,
    bool? isLoadingEvents,
    bool? isLoadingSearch,
    bool? isOffline,
    bool? isLocationEnabled,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      recommendedPlaces: recommendedPlaces ?? this.recommendedPlaces,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      popularEvents: popularEvents ?? this.popularEvents,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingRecommended: isLoadingRecommended ?? this.isLoadingRecommended,
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
      isLoadingEvents: isLoadingEvents ?? this.isLoadingEvents,
      isLoadingSearch: isLoadingSearch ?? this.isLoadingSearch,
      isOffline: isOffline ?? this.isOffline,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentLocation,
    isLoadingLocation,
    selectedCategory,
    selectedIndex,
    recommendedPlaces,
    nearbyPlaces,
    popularEvents,
    searchResults,
    isSearching,
    searchQuery,
    isLoadingRecommended,
    isLoadingNearby,
    isLoadingEvents,
    isLoadingSearch,
    isOffline,
    isLocationEnabled,
    errorMessage,
  ];
}
