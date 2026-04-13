import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_event.dart';
import 'package:yatrikaa/Frontend/views/Routes/app_routes.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/core/services/backend_health_manager.dart';
import 'package:yatrikaa/Frontend/core/bloc/connectivity/connectivity_bloc.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_observer.dart';
import 'package:yatrikaa/Frontend/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Global future to track app initialization status across the app.
late Future<void> appInitialization;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Background Message] Received message: ${message.messageId}');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start initialization immediately but don't await here 
  // to allow the UI to render its first frame instantly.
  appInitialization = _initializeCore();
  
  runApp(const MyApp());
}

Future<void> _initializeCore() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    NotificationService().initialize();
    await BackendHealthManager.instance.initialize(useLocal: true);
    
    // Ensure at least 2 seconds for services to soak
    await Future.delayed(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      key: const ValueKey('AppRoot'),
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AppStarted())),
        BlocProvider(create: (_) => TravelBloc()),
        BlocProvider(
          create: (_) => ConnectivityBloc()..add(ConnectivityStarted()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            navigatorKey: MyApp.navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              textTheme: GoogleFonts.montserratTextTheme(
                Theme.of(context).textTheme,
              ),
              colorSchemeSeed: primaryBlue,
            ),
            initialRoute: RouteNames.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            navigatorObservers: [
              ConnectivityRouteObserver(context.read<ConnectivityBloc>()),
            ],
            builder: (context, child) {
              return child ?? const SizedBox();
            },
          );
        },
      ),
    );
  }
}

class StaticSplashView extends StatelessWidget {
  const StaticSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/LogoPadded.png',
              width: 150,
            ),
            const SizedBox(height: 24),
            Text(
              'YATRIKAA',
              style: GoogleFonts.montserrat(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Discover • Plan • Travel',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
