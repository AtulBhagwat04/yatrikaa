import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'route_names.dart';

// Import Screens


class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());


      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text("No route found"),
            ),
          ),
        );
    }
  }
}
