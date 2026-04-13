import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/main.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_event.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<UpdateAuthCounts>(_onUpdateAuthCounts);
    on<SyncAuthCounts>(_onSyncAuthCounts);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    // Ensure Firebase and background services are ready before continuing
    await appInitialization;
    
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final results = await Future.wait([
        _authService.getRole(),
        _authService.getGuideRequestStatus(),
        _authService.getName(),
        _authService.getEmail(),
        _authService.getUserId(),
        _authService.getTripsCount(),
        _authService.getSavedCount(),
        _authService.getReviewsCount(),
        _authService.getPostsCount(),
        _authService.getPhoneNumber(),
        _authService.getGender(),
        _authService.getProfilePicture(),
      ]);

      if (state is! AuthLoading) return;
      
      emit(
        Authenticated(
          id: results[4] as String? ?? '',
          role: results[0] as String? ?? 'user',
          guideRequestStatus: results[1] as String? ?? 'None',
          name: results[2] as String? ?? 'Traveler',
          email: results[3] as String? ?? '',
          tripsCount: results[5] as int? ?? 0,
          savedCount: results[6] as int? ?? 0,
          reviewsCount: results[7] as int? ?? 0,
          postsCount: results[8] as int? ?? 0,
          phoneNumber: results[9] as String?,
          gender: results[10] as String?,
          profilePicture: results[11] as String?,
        ),
      );
    } else {
      emit(Unauthenticated());
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    emit(
      Authenticated(
        id: event.id,
        role: event.role,
        guideRequestStatus: event.guideRequestStatus,
        name: event.name,
        email: event.email,
        tripsCount: event.tripsCount,
        savedCount: event.savedCount,
        reviewsCount: event.reviewsCount,
        postsCount: event.postsCount,
        phoneNumber: event.phoneNumber,
        gender: event.gender,
        profilePicture: event.profilePicture,
      ),
    );
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authService.logout();
    emit(Unauthenticated());
  }

  Future<void> _onUpdateAuthCounts(
    UpdateAuthCounts event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      final newTripsCount = event.tripsCount ?? currentState.tripsCount;
      final newSavedCount = event.savedCount ?? currentState.savedCount;
      final newReviewsCount = event.reviewsCount ?? currentState.reviewsCount;
      final newPostsCount = event.postsCount ?? currentState.postsCount;

      final List<Future<void>> updates = [];
      if (event.tripsCount != null) {
        updates.add(_authService.updateTripsCount(newTripsCount));
      }
      if (event.savedCount != null) {
        updates.add(_authService.updateSavedCount(newSavedCount));
      }
      if (event.reviewsCount != null) {
        updates.add(_authService.updateReviewsCount(newReviewsCount));
      }
      if (event.postsCount != null) {
        updates.add(_authService.updatePostsCount(newPostsCount));
      }

      if (updates.isNotEmpty) {
        await Future.wait(updates);
      }

      if (state is! Authenticated) return;

      emit(
        Authenticated(
          id: currentState.id,
          role: currentState.role,
          guideRequestStatus: currentState.guideRequestStatus,
          name: currentState.name,
          email: currentState.email,
          tripsCount: newTripsCount,
          savedCount: newSavedCount,
          reviewsCount: newReviewsCount,
          postsCount: newPostsCount,
          phoneNumber: currentState.phoneNumber,
          gender: currentState.gender,
          profilePicture: currentState.profilePicture,
        ),
      );
    }
  }

  Future<void> _onSyncAuthCounts(
    SyncAuthCounts event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken(true); // force refresh
          if (idToken != null) {
            if (state is! Authenticated) return;

            final data = await _authService.syncWithBackend(idToken);
            
            if (state is! Authenticated) return;

            emit(
              Authenticated(
                id: data['id'] ?? (state as Authenticated).id,
                role: data['role'] ?? (state as Authenticated).role,
                guideRequestStatus:
                    data['guideRequestStatus'] ?? (state as Authenticated).guideRequestStatus,
                name: data['name'] ?? (state as Authenticated).name,
                email: data['email'] ?? (state as Authenticated).email,
                tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
                savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
                reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
                postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
                phoneNumber: data['phoneNumber'] ?? (state as Authenticated).phoneNumber,
                gender: data['gender'] ?? (state as Authenticated).gender,
                profilePicture: data['profilePicture'] ?? (state as Authenticated).profilePicture,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[AuthBloc] Sync failed: $e');
      }
    }
  }
}
