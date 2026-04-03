import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String id;
  final String role;
  final String name;
  final String email;
  final String guideRequestStatus;
  final int tripsCount;
  final int savedCount;
  final int reviewsCount;
  final int postsCount;

  const LoginSuccess({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.guideRequestStatus = 'None',
    this.tripsCount = 0,
    this.savedCount = 0,
    this.reviewsCount = 0,
    this.postsCount = 0,
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
  ];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}
