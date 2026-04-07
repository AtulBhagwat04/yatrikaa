import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/screens/splash/splash_screen_bloc.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _navigateToNext(BuildContext context, AuthState authState) {
    if (authState is Authenticated) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } else if (authState is Unauthenticated) {
      Navigator.pushReplacementNamed(context, RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashBloc()..add(StartAnimation()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              final splashState = context.read<SplashBloc>().state;
              if (splashState.navigationReady) {
                _navigateToNext(context, authState);
              }
            },
          ),
          BlocListener<SplashBloc, SplashState>(
            listener: (context, splashState) {
              if (splashState.navigationReady) {
                final authState = context.read<AuthBloc>().state;
                _navigateToNext(context, authState);
              }
            },
          ),
        ],
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light, 
            systemNavigationBarColor: primaryBlue,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Container(
            decoration: const BoxDecoration(color: primaryBlue),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Main Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Name
                        Text(
                          'YATRIKAA',
                          style: GoogleFonts.montserrat(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                            color: appWhite,
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 600.ms),

                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          'Discover • Plan • Travel',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                            color: appWhite.withOpacity(0.85),
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 600.ms),
                      ],
                    ),
                  ),

                  // Bottom loading indicator and Made in India tag
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Loading bar
                        SizedBox(
                          width: 60,
                          height: 2,
                          child: LinearProgressIndicator(
                            backgroundColor: appWhite.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              appWhite,
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 24),

                        // Made in India Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: appWhite.withOpacity(0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MADE IN INDIA',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: appWhite.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
