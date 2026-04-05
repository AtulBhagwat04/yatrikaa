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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    // Set background messaging handler early
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize notification service
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase or Notification initialization failed: $e');
  }
  BackendHealthManager.instance.initialize(useLocal: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
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
  }
}
