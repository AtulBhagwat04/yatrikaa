import 'package:equatable/equatable.dart';

abstract class SignupState extends Equatable {
  const SignupState();

  @override
  List<Object?> get props => [];
}

class SignupInitial extends SignupState {}

class SignupLoading extends SignupState {}

class SignupSuccess extends SignupState {
  final String id;
  final String role;
  final String name;
  final String email;
  final String guideRequestStatus;
  final int tripsCount;
  final int savedCount;
  final int reviewsCount;
  final int postsCount;

  const SignupSuccess({
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

class SignupFailure extends SignupState {
  final String message;

  const SignupFailure(this.message);

  @override
  List<Object?> get props => [message];
}
