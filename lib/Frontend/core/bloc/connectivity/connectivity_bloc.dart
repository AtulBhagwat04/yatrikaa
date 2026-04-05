import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ConnectivityEvent {
  const ConnectivityEvent();
}

class ConnectivityStarted extends ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final bool isOffline;
  const ConnectivityChanged(this.isOffline);
}

class RouteChanged extends ConnectivityEvent {
  final String routeName;
  const RouteChanged(this.routeName);
}

class ConnectivityState {
  final bool isOffline;
  final String? currentRoute;
  const ConnectivityState({this.isOffline = false, this.currentRoute});

  ConnectivityState copyWith({bool? isOffline, String? currentRoute}) {
    return ConnectivityState(
      isOffline: isOffline ?? this.isOffline,
      currentRoute: currentRoute ?? this.currentRoute,
    );
  }
}

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ConnectivityBloc() : super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityChanged>((event, emit) {
      emit(state.copyWith(isOffline: event.isOffline));
    });
    on<RouteChanged>((event, emit) {
      emit(state.copyWith(currentRoute: event.routeName));
    });
  }

  void _onStarted(ConnectivityStarted event, Emitter<ConnectivityState> emit) {
    _connectivitySubscription?.cancel();

    // Initial check
    Future.delayed(const Duration(milliseconds: 500), () async {
      final results = await Connectivity().checkConnectivity();
      await _handleConnectivityChange(results);
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    final hasInterface =
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (!hasInterface) {
      add(const ConnectivityChanged(true));
      return;
    }

    // Even if interface is up, check if we can actually reach the internet
    final hasInternet = await _checkRealInternet();
    add(ConnectivityChanged(!hasInternet));
  }

  Future<bool> _checkRealInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
