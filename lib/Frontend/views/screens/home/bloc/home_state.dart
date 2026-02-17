import 'package:equatable/equatable.dart';
import 'package:bhatkanti_app/Frontend/core/models/place_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final String currentLocation;
  final bool isLoadingLocation;
  final String selectedCategory;
  final int selectedIndex;
  final List<PlaceModel> recommendedPlaces;
  final List<PlaceModel> nearbyPlaces;
  final bool isLoadingRecommended;
  final bool isLoadingNearby;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.currentLocation = "Fetching location...",
    this.isLoadingLocation = true,
    this.selectedCategory = "All",
    this.selectedIndex = 0,
    this.recommendedPlaces = const [],
    this.nearbyPlaces = const [],
    this.isLoadingRecommended = true,
    this.isLoadingNearby = true,
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
    bool? isLoadingRecommended,
    bool? isLoadingNearby,
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
      isLoadingRecommended: isLoadingRecommended ?? this.isLoadingRecommended,
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
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
    isLoadingRecommended,
    isLoadingNearby,
    errorMessage,
  ];
}
