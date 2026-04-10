import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// EVENTS
abstract class SplashEvent {}

class StartAnimation extends SplashEvent {}

/// STATE
class SplashState {
  final bool showIcon;
  final bool showText;
  final bool navigationReady;

  const SplashState({
    this.showIcon = false,
    this.showText = false,
    this.navigationReady = false,
  });

  SplashState copyWith({
    bool? showIcon,
    bool? showText,
    bool? navigationReady,
  }) {
    return SplashState(
      showIcon: showIcon ?? this.showIcon,
      showText: showText ?? this.showText,
      navigationReady: navigationReady ?? this.navigationReady,
    );
  }
}

/// BLOC
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashState()) {
    on<StartAnimation>(_startAnimation);
  }

  Future<void> _startAnimation(
    StartAnimation event,
    Emitter<SplashState> emit,
  ) async {
    // Step 1: Instant start for animations after native splash
    await Future.delayed(const Duration(milliseconds: 50));
    emit(state.copyWith(showIcon: true));

    // Step 2: Show text and tagline
    await Future.delayed(const Duration(milliseconds: 300));
    emit(state.copyWith(showText: true));

    // Step 3: Hold for full brand experience (Extended to meet user request of 3-4s)
    await Future.delayed(const Duration(milliseconds: 3150));

    // Step 4: Finalize and trigger navigation
    emit(state.copyWith(navigationReady: true));
  }
}
