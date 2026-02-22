import 'package:equatable/equatable.dart';

abstract class PlaceDetailsEvent extends Equatable {
  const PlaceDetailsEvent();

  @override
  List<Object?> get props => [];
}

class PlaceDetailsStarted extends PlaceDetailsEvent {
  final String placeId;
  const PlaceDetailsStarted(this.placeId);

  @override
  List<Object?> get props => [placeId];
}

class PlaceDetailsFavoriteToggled extends PlaceDetailsEvent {}

class PlaceDetailsBookmarkToggled extends PlaceDetailsEvent {}
