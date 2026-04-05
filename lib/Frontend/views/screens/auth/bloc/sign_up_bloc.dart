import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/sign_up_event.dart';
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/sign_up_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final AuthService _authService = AuthService();

  SignupBloc() : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());

    try {
      final response = await _authService.register(
        event.name,
        event.email,
        event.password,
        event.role,
      );
      emit(
        SignupSuccess(
          id: response['id'] ?? '',
          role: response['role'] ?? event.role,
          guideRequestStatus: response['guideRequestStatus'] ?? 'None',
          name: response['name'] ?? event.name,
          email: response['email'] ?? event.email,
          tripsCount: (response['tripsCount'] as num?)?.toInt() ?? 0,
          savedCount: (response['savedCount'] as num?)?.toInt() ?? 0,
          reviewsCount: (response['reviewsCount'] as num?)?.toInt() ?? 0,
          postsCount: (response['postsCount'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (e) {
      emit(SignupFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
