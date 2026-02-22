import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String role;
  final String name;
  final String email;
  final int tripsCount;
  final int savedCount;
  final int reviewsCount;

  const LoggedIn({
    required this.role,
    required this.name,
    required this.email,
    this.tripsCount = 0,
    this.savedCount = 0,
    this.reviewsCount = 0,
  });

  @override
  List<Object?> get props => [
    role,
    name,
    email,
    tripsCount,
    savedCount,
    reviewsCount,
  ];
}

class LoggedOut extends AuthEvent {}
