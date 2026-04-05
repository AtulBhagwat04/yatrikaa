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
