import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/sign_up_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/sign_up_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc() : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(
      SignupSubmitted event,
      Emitter<SignupState> emit,
      ) async {
    emit(SignupLoading());

    try {
      // 🔥 TODO: Call backend API here
      // final response = await authRepository.signup(...);

      // For now we just simulate waiting for backend integration
      await Future.delayed(const Duration(milliseconds: 300));

      // Remove this later once backend connected
      emit(SignupSuccess());

    } catch (e) {
      emit(SignupFailure(e.toString()));
    }
  }
}
