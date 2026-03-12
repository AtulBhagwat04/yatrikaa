class RouteNames {
  // Main
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  // Auth
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String otp = '/auth/otp';

  // Places
  static const String placeDetails = '/place-details';
  static const String eventDetails = '/event-details';
  static const String map = '/map';

  // User
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String notifications = '/profile/notifications';
  static const String helpCenter = '/profile/help';
  static const String privacyPolicy = '/profile/privacy';
  static const String about = '/profile/about';
  static const String trips = '/profile/trips';
  static const String reviews = '/profile/reviews';
  static const String myPosts = '/profile/my-posts';

  // Guide Panel
  static const String guideDashboard = '/guide/dashboard';
  static const String manageTours = '/guide/tours';
  static const String bookingRequests = '/guide/bookings';

  // Admin Tools
  static const String managePlaces = '/admin/places';
  static const String reviewModeration = '/admin/reviews';
  static const String manageEvents = '/admin/events';

  // System Authority (Super Admin)
  static const String userManagement = '/super-admin/users';
  static const String analytics = '/super-admin/analytics';
  static const String systemConfig = '/super-admin/config';
  static const String addPlace = '/admin/places/add';
  static const String addEvent = '/admin/events/add';

  // Social (Phase 2+)
  static const String tripFeed = '/trip-feed';

  // Travel Packages
  static const String packages = '/packages';
  static const String packageDetails = '/packages/details';
  static const String createPackage = '/packages/create';
  static const String myPackages = '/packages/mine';
  static const String userBookings = '/bookings';

  // Chat (Phase 3+)
  static const String chat = '/chat';
}
