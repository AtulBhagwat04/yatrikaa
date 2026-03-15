import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';

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
import 'package:bhatkanti_app/Frontend/views/screens/profile/reviews_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/manage_places_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/review_moderation_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/user_management_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/guide_dashboard_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/generic_management_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/add_place_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/my_posts_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/splash/splash_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/admin/add_event_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/events/event_details_screen.dart';
import 'package:bhatkanti_app/Frontend/core/models/event_model.dart';
import 'package:bhatkanti_app/Frontend/views/screens/profile/manage_events_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/login_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/place_details/place_details_screen.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/packages_discovery_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/package_details_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/create_package_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/my_packages_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/user_bookings_screen.dart';
import 'package:bhatkanti_app/Frontend/views/screens/search/search_screen.dart';

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

      case RouteNames.search:
        return _fadeRoute(const SearchScreen());

      case RouteNames.placeDetails:
        final placeId = settings.arguments as String?;
        return _fadeRoute(PlaceDetailsScreen(placeId: placeId ?? ''));

      case RouteNames.eventDetails:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return _fadeRoute(
            EventDetailsScreen(
              eventId: args['id'] ?? '',
              event: args['event'] as EventModel?,
            ),
          );
        }
        return _fadeRoute(EventDetailsScreen(eventId: (args as String?) ?? ''));

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
        return _fadeRoute(const UserBookingsScreen());

      // ── Travel Packages ──────────────────────────────────────────────────────
      case RouteNames.packages:
        return _fadeRoute(const PackagesDiscoveryScreen());

      case RouteNames.packageDetails:
        final packageId = settings.arguments as String?;
        return _fadeRoute(PackageDetailsScreen(packageId: packageId ?? ''));

      case RouteNames.createPackage:
        return _fadeRoute(const CreatePackageScreen());

      case RouteNames.myPackages:
        return _fadeRoute(const MyPackagesScreen());

      case RouteNames.userBookings:
        return _fadeRoute(const UserBookingsScreen());

      case RouteNames.reviews:
        return _fadeRoute(const ReviewsScreen());
      case RouteNames.myPosts:
        return _fadeRoute(const MyPostsScreen());

      // Guide Panel
      case RouteNames.guideDashboard:
        return _fadeRoute(const GuideDashboardScreen());
      case RouteNames.manageTours:
        return _fadeRoute(const MyPackagesScreen());
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
      case RouteNames.manageEvents:
        return _fadeRoute(const ManageEventsScreen());
      case RouteNames.addEvent:
        return _fadeRoute(const AddEventScreen());

      // Admin Management
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
            themeColor: adminColor,
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
            themeColor: adminColor,
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
