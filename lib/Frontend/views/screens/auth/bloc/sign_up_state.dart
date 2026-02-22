import 'package:equatable/equatable.dart';

abstract class SignupState extends Equatable {
  const SignupState();

  @override
  List<Object?> get props => [];
}

class SignupInitial extends SignupState {}

class SignupLoading extends SignupState {}

class SignupSuccess extends SignupState {
  final String role;
  final String name;
  final String email;
  final int tripsCount;
  final int savedCount;
  final int reviewsCount;

  const SignupSuccess({
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

class SignupFailure extends SignupState {
  final String message;

  const SignupFailure(this.message);

  @override
  List<Object?> get props => [message];
}
