import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bhatkanti_app/Frontend/views/screens/onboarding/onboarding_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/login_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/sign_up_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/home/home_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/profile_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/edit_profile_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/change_password_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/notifications_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/help_center_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/privacy_policy_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/about_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/favorites_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/trips_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/reviews_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/manage_places_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/review_moderation_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/user_management_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/guide_dashboard_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/generic_management_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/add_place_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/splash/splash_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/login_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/place_details/place_details_screen.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _fadeRoute(const SplashScreen());

      case RouteNames.onboarding:
        return _fadeRoute(const OnboardingScreen());

      case RouteNames.login:
        return _fadeRoute(
          BlocProvider(create: (_) => LoginBloc(), child: const LoginScreen()),
        );

      case RouteNames.signup:
        return _fadeRoute(const SignUpScreen());

      case RouteNames.home:
        return _fadeRoute(const HomeScreen());

      case RouteNames.placeDetails:
        final placeId = settings.arguments as String?;
        return _fadeRoute(PlaceDetailsScreen(placeId: placeId ?? ''));

      case RouteNames.profile:
        return _fadeRoute(const ProfileScreen());

      case RouteNames.editProfile:
        return _fadeRoute(const EditProfileScreen());

      case RouteNames.changePassword:
        return _fadeRoute(const ChangePasswordScreen());

      case RouteNames.notifications:
        return _fadeRoute(const NotificationsScreen());

      case RouteNames.helpCenter:
        return _fadeRoute(const HelpCenterScreen());

      case RouteNames.privacyPolicy:
        return _fadeRoute(const PrivacyPolicyScreen());

      case RouteNames.about:
        return _fadeRoute(const AboutScreen());

      case RouteNames.favorites:
        return _fadeRoute(const FavoritesScreen());

      case RouteNames.trips:
        return _fadeRoute(const TripsScreen());

      case RouteNames.reviews:
        return _fadeRoute(const ReviewsScreen());

      // Guide Panel
      case RouteNames.guideDashboard:
        return _fadeRoute(const GuideDashboardScreen());
      case RouteNames.manageTours:
        return _fadeRoute(
          const GenericManagementScreen(
            title: 'Manage Tours',
            emptyTitle: 'No Tours Found',
            emptySubtitle:
                'Start creating amazing tour packages for travelers to browse and book!',
            icon: Icons.tour_rounded,
            themeColor: Color(0xFFEA580C),
          ),
        );
      case RouteNames.bookingRequests:
        return _fadeRoute(
          const GenericManagementScreen(
            title: 'Booking Requests',
            emptyTitle: 'No Pending Bookings',
            emptySubtitle:
                'Your traveler requests will appear here once they start booking your experiences.',
            icon: Icons.calendar_today_outlined,
            themeColor: Color(0xFFEA580C),
          ),
        );

      // Admin Tools
      case RouteNames.managePlaces:
        return _fadeRoute(const ManagePlacesScreen());
      case RouteNames.addPlace:
        return _fadeRoute(const AddPlaceScreen());
      case RouteNames.reviewModeration:
        return _fadeRoute(const ReviewModerationScreen());

      // Super Admin
      case RouteNames.userManagement:
        return _fadeRoute(const UserManagementScreen());
      case RouteNames.analytics:
        return _fadeRoute(
          const GenericManagementScreen(
            title: 'System Analytics',
            emptyTitle: 'Syncing Data...',
            emptySubtitle:
                'Deep analytics and system performance metrics are being processed. Check back shortly!',
            icon: Icons.analytics_outlined,
            themeColor: Color(0xFF7C3AED),
          ),
        );
      case RouteNames.systemConfig:
        return _fadeRoute(
          const GenericManagementScreen(
            title: 'System Configuration',
            emptyTitle: 'Default Settings Active',
            emptySubtitle:
                'The system is running on optimized default parameters. You can modify core variables here.',
            icon: Icons.tune_rounded,
            themeColor: Color(0xFF7C3AED),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("No route found"))),
        );
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
