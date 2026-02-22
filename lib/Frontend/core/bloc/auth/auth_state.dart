import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  final String role;
  final String name;
  final String email;
  final int tripsCount;
  final int savedCount;
  final int reviewsCount;

  const Authenticated({
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

class Unauthenticated extends AuthState {}

class AuthLoading extends AuthState {}
