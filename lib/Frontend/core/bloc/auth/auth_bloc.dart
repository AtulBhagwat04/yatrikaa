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
      final role = await _authService.getRole();
      final guideStatus = await _authService.getGuideRequestStatus();
      final name = await _authService.getName();
      final email = await _authService.getEmail();
      final id = await _authService.getUserId();
      final tripsCount = await _authService.getTripsCount();
      final savedCount = await _authService.getSavedCount();
      final reviewsCount = await _authService.getReviewsCount();
      final postsCount = await _authService.getPostsCount();
      emit(
        Authenticated(
          id: id ?? '',
          role: role ?? 'user',
          guideRequestStatus: guideStatus,
          name: name ?? 'Traveler',
          email: email ?? '',
          tripsCount: tripsCount,
          savedCount: savedCount,
          reviewsCount: reviewsCount,
          postsCount: postsCount,
          phoneNumber: await _authService.getPhoneNumber(),
          gender: await _authService.getGender(),
          profilePicture: await _authService.getProfilePicture(),
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

      if (event.tripsCount != null) {
        await _authService.updateTripsCount(newTripsCount);
      }
      if (event.savedCount != null) {
        await _authService.updateSavedCount(newSavedCount);
      }
      if (event.reviewsCount != null) {
        await _authService.updateReviewsCount(newReviewsCount);
      }
      if (event.postsCount != null) {
        await _authService.updatePostsCount(newPostsCount);
      }

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
            final data = await _authService.syncWithBackend(idToken);
            emit(
              Authenticated(
                id: data['id'] ?? currentState.id,
                role: data['role'] ?? currentState.role,
                guideRequestStatus:
                    data['guideRequestStatus'] ?? currentState.guideRequestStatus,
                name: data['name'] ?? currentState.name,
                email: data['email'] ?? currentState.email,
                tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
                savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
                reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
                postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
                phoneNumber: data['phoneNumber'] ?? currentState.phoneNumber,
                gender: data['gender'] ?? currentState.gender,
                profilePicture: data['profilePicture'] ?? currentState.profilePicture,
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
