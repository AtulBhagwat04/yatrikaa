import 'package:flutter_bloc/flutter_bloc.dart';

/// EVENTS
abstract class OnboardingEvent {}

class PageChanged extends OnboardingEvent {
  final int index;
  PageChanged(this.index);
}

/// STATE
class OnboardingState {
  final int currentIndex;
  final bool isLastPage;

  const OnboardingState({required this.currentIndex, required this.isLastPage});

  factory OnboardingState.initial() {
    return const OnboardingState(currentIndex: 0, isLastPage: false);
  }

  OnboardingState copyWith({int? currentIndex, bool? isLastPage}) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      isLastPage: isLastPage ?? this.isLastPage,
    );
  }
}

/// BLOC
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final int totalPages;

  OnboardingBloc({required this.totalPages})
    : super(OnboardingState.initial()) {
    on<PageChanged>(_onPageChanged);
  }

  void _onPageChanged(PageChanged event, Emitter<OnboardingState> emit) {
    emit(
      state.copyWith(
        currentIndex: event.index,
        isLastPage: event.index == totalPages - 1,
      ),
    );
  }
}
