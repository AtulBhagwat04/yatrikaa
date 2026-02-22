import 'package:equatable/equatable.dart';
import '../../../../core/models/place_model.dart';

enum PlaceDetailsStatus { initial, loading, success, failure }

class PlaceDetailsState extends Equatable {
  final PlaceDetailsStatus status;
  final PlaceModel? place;
  final bool isFavorite;
  final bool isBookmarked;
  final String? errorMessage;

  const PlaceDetailsState({
    this.status = PlaceDetailsStatus.initial,
    this.place,
    this.isFavorite = false,
    this.isBookmarked = false,
    this.errorMessage,
  });

  PlaceDetailsState copyWith({
    PlaceDetailsStatus? status,
    PlaceModel? place,
    bool? isFavorite,
    bool? isBookmarked,
    String? errorMessage,
  }) {
    return PlaceDetailsState(
      status: status ?? this.status,
      place: place ?? this.place,
      isFavorite: isFavorite ?? this.isFavorite,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    place,
    isFavorite,
    isBookmarked,
    errorMessage,
  ];
}
