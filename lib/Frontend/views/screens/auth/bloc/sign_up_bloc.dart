import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/sign_up_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/sign_up_state.dart';

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
          role: response['role'] ?? event.role,
          name: response['name'] ?? event.name,
          email: response['email'] ?? event.email,
          tripsCount: response['tripsCount'] ?? 0,
          savedCount: response['savedCount'] ?? 0,
          reviewsCount: response['reviewsCount'] ?? 0,
        ),
      );
    } catch (e) {
      emit(SignupFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
