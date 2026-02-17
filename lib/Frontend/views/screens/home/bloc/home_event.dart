import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {}

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
