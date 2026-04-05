import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yatrikaa/Frontend/core/models/event_model.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {}

class HomeLoadCache extends HomeEvent {}

class HomeConnectivityChanged extends HomeEvent {
  final bool isOffline;
  const HomeConnectivityChanged(this.isOffline);
  @override
  List<Object?> get props => [isOffline];
}

class HomeLocationServiceStatusChanged extends HomeEvent {
  final bool isEnabled;
  const HomeLocationServiceStatusChanged(this.isEnabled);
  @override
  List<Object?> get props => [isEnabled];
}

class HomeLocationRefreshRequested extends HomeEvent {}

class HomeLocationUpdated extends HomeEvent {
  final Position position;
  const HomeLocationUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

class HomeCategoryChanged extends HomeEvent {
  final String category;
  const HomeCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class HomeTabChanged extends HomeEvent {
  final int index;
  const HomeTabChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class HomeSearchRequested extends HomeEvent {
  final String query;
  const HomeSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

class HomeSearchCleared extends HomeEvent {}

class HomeEventUpdateEvent extends HomeEvent {
  final EventModel event;
  const HomeEventUpdateEvent(this.event);

  @override
  List<Object> get props => [event];
}
