import 'package:bhatkanti_app/Frontend/views/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/fade_route.dart';
import '../auth/login_screen.dart';
import 'splash_screen_bloc.dart';
import '../../../core/constants/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashBloc()..add(StartAnimation()),
      child: BlocConsumer<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state.navigationReady) {
            Navigator.of(context).pushReplacement(
              RouteUtils.fadeRoute(
                page: const OnboardingScreen(),
              ),
            );
          }
        },
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
                    onboardingBlueVeryLight
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //icon animation
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

                    //text animation
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
    );
  }
}
