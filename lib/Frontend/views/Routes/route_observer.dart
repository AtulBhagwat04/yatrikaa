import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/bloc/connectivity/connectivity_bloc.dart';

class ConnectivityRouteObserver extends NavigatorObserver {
  final ConnectivityBloc connectivityBloc;

  ConnectivityRouteObserver(this.connectivityBloc);

  void _updateRoute(Route<dynamic>? route) {
    if (route != null && route.settings.name != null) {
      connectivityBloc.add(RouteChanged(route.settings.name!));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateRoute(previousRoute);
  }
}
