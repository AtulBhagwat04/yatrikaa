import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  final String id;
  final String role;
  final String name;
  final String email;
  final String guideRequestStatus;
  final int tripsCount;
  final int savedCount;
  final int reviewsCount;
  final int postsCount;
  final String? phoneNumber;
  final String? gender;
  final String? profilePicture;

  const Authenticated({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.guideRequestStatus = 'None',
    this.tripsCount = 0,
    this.savedCount = 0,
    this.reviewsCount = 0,
    this.postsCount = 0,
    this.phoneNumber,
    this.gender,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [
    id,
    role,
    name,
    email,
    guideRequestStatus,
    tripsCount,
    savedCount,
    reviewsCount,
    postsCount,
    phoneNumber,
    gender,
    profilePicture,
  ];
}

class Unauthenticated extends AuthState {}

class AuthLoading extends AuthState {}
