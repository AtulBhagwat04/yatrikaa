import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/login_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService = AuthService();

  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final response = await _authService.login(event.email, event.password);
      emit(
        LoginSuccess(
          id: response['id'] ?? '',
          role: response['role'] ?? 'user',
          guideRequestStatus: response['guideRequestStatus'] ?? 'None',
          name: response['name'] ?? 'Traveler',
          email: response['email'] ?? event.email,
          tripsCount: (response['tripsCount'] as num?)?.toInt() ?? 0,
          savedCount: (response['savedCount'] as num?)?.toInt() ?? 0,
          reviewsCount: (response['reviewsCount'] as num?)?.toInt() ?? 0,
          postsCount: (response['postsCount'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (e) {
      emit(LoginFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
