import 'package:equatable/equatable.dart';
import '../../../../core/models/place_model.dart';

abstract class PlaceDetailsEvent extends Equatable {
  const PlaceDetailsEvent();

  @override
  List<Object?> get props => [];
}

class PlaceDetailsStarted extends PlaceDetailsEvent {
  final String placeId;
  final PlaceModel? initialPlace;

  const PlaceDetailsStarted(this.placeId, {this.initialPlace});

  @override
  List<Object?> get props => [placeId, initialPlace];
}

class PlaceDetailsFavoriteToggled extends PlaceDetailsEvent {}

class PlaceDetailsBookmarkToggled extends PlaceDetailsEvent {}

class PlaceReviewAdded extends PlaceDetailsEvent {
  final double rating;
  final String comment;

  const PlaceReviewAdded({required this.rating, required this.comment});

  @override
  List<Object?> get props => [rating, comment];
}

class PlaceReviewUpdated extends PlaceDetailsEvent {
  final String reviewId;
  final double rating;
  final String comment;

  const PlaceReviewUpdated({
    required this.reviewId,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [reviewId, rating, comment];
}

class PlaceReviewDeleted extends PlaceDetailsEvent {
  final String reviewId;

  const PlaceReviewDeleted({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}
