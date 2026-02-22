import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_event.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final role = await _authService.getRole();
      final name = await _authService.getName();
      final email = await _authService.getEmail();
      final tripsCount = await _authService.getTripsCount();
      final savedCount = await _authService.getSavedCount();
      final reviewsCount = await _authService.getReviewsCount();
      emit(
        Authenticated(
          role: role ?? 'user',
          name: name ?? 'Traveler',
          email: email ?? '',
          tripsCount: tripsCount,
          savedCount: savedCount,
          reviewsCount: reviewsCount,
        ),
      );
    } else {
      emit(Unauthenticated());
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    emit(
      Authenticated(
        role: event.role,
        name: event.name,
        email: event.email,
        tripsCount: event.tripsCount,
        savedCount: event.savedCount,
        reviewsCount: event.reviewsCount,
      ),
    );
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authService.logout();
    emit(Unauthenticated());
  }
}
