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
import 'package:yatrikaa/Frontend/views/widgets/global_connectivity_banner.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_observer.dart';
import 'package:yatrikaa/Frontend/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Background Message] Received message: ${message.messageId}');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      NotificationService().initialize();
      BackendHealthManager.instance.initialize(useLocal: true);
    } catch (e) {
      debugPrint('Bootstrap error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashLoadingView(),
          );
        }

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
                  return Column(
                    children: [
                      Expanded(child: child ?? const SizedBox()),
                      const GlobalConnectivityBanner(),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class SplashLoadingView extends StatelessWidget {
  const SplashLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'YATRIKAA',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
                color: Colors.white,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Discover • Plan • Travel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
