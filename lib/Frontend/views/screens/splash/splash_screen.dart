import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/screens/splash/splash_screen_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _navigateToNext(BuildContext context, AuthState authState) {
    if (authState is Authenticated) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } else if (authState is Unauthenticated) {
      Navigator.pushReplacementNamed(context, RouteNames.onboarding);
    }
    // If AuthLoading or AuthInitial, we do nothing and wait for the AuthBloc listener
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
        child: BlocBuilder<SplashBloc, SplashState>(
          builder: (context, state) {
            return Scaffold(
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 2.2,
                    colors: [
                      onboardingBlueVeryLight,
                      onboardingBlueLight,
                      onboardingBlueVeryLight,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: state.showIcon ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        child: AnimatedOpacity(
                          opacity: state.showIcon ? 1 : 0,
                          duration: const Duration(milliseconds: 600),
                          child: const Icon(
                            Icons.travel_explore_rounded,
                            size: 96,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedSlide(
                        offset: state.showText
                            ? Offset.zero
                            : const Offset(0, 0.3),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutExpo,
                        child: AnimatedOpacity(
                          opacity: state.showText ? 1 : 0,
                          duration: const Duration(milliseconds: 700),
                          child: Column(
                            children: [
                              Text(
                                'BHATKANTI',
                                style: GoogleFonts.montserrat(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 7,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Discover • Plan • Travel',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 3,
                                  color: primaryBlue.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
