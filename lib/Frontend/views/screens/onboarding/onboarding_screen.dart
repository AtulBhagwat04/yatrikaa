import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_button.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_indicator.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';

import '../auth/login_screen.dart';
import 'onboarding_bloc.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(totalPages: _pages.length),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _pages[state.currentIndex].gradient,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.13),

                  //page view
                  SizedBox(
                    height: screenHeight * 0.55,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        context.read<OnboardingBloc>().add(PageChanged(index));
                      },
                      itemBuilder: (context, index) {
                        final data = _pages[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// Image
                            SizedBox(
                              height: screenHeight * 0.32,
                              child: Image.asset(
                                data.image,
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.l),

                            // title
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.l,
                              ),
                              child: AppText.heading(
                                data.title,
                                align: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.s),

                            //subtitle
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              child: AppText.body(
                                data.subtitle,
                                align: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const Spacer(),
                  AppPageIndicator(
                    count: _pages.length,
                    currentIndex: state.currentIndex,
                  ),

                  const SizedBox(height: AppSpacing.l),

                  //button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                    ),
                    child: AppButton(
                      text: state.isLastPage
                          ? AppStrings.onboardingBtnStarted
                          : AppStrings.onboardingBtnNext,
                      onPressed: () {
                        if (state.isLastPage) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

//onboarding info
final List<_OnboardingData> _pages = [
  _OnboardingData(
    title: AppStrings.onboardingTitle1,
    subtitle: AppStrings.onboardingSubTitle1,
    image: 'assets/images/onboarding_1.png',
    gradient: [onboardingBlueVeryLight, onboardingBlueLight],
  ),
  _OnboardingData(
    title: AppStrings.onboardingTitle2,
    subtitle: AppStrings.onboardingSubTitle2,
    image: 'assets/images/onboarding_2.png',
    gradient: [onboardingBlueSoft, onboardingBlueVeryLight],
  ),
  _OnboardingData(
    title: AppStrings.onboardingTitle3,
    subtitle: AppStrings.onboardingSubTitle3,
    image: 'assets/images/onboarding_3.png',
    gradient: [onboardingBlue, onboardingBlueLight],
  ),
];

class _OnboardingData {
  final String title;
  final String subtitle;
  final String image;
  final List<Color> gradient;
  _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.gradient,
  });
}
