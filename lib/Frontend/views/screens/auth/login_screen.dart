import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_button.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_input_fields.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_event.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/login_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/login_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _loginBloc = LoginBloc();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _loginBloc.close();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      _loginBloc.add(
        LoginSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _loginBloc,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [onboardingBlueVeryLight, onboardingBlueLight],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: size.height * 0.2),
                        AppText.heading(
                          AppStrings.welcomeBack,
                          align: TextAlign.left,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        AppText.body(
                          AppStrings.loginSubtitle,
                          align: TextAlign.left,
                        ),
                        const SizedBox(height: AppSpacing.l),
                        AppInputField(
                          controller: _emailController,
                          hint: AppStrings.emailHint,
                          prefixIcon: Icons.email_outlined,
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_passwordFocus),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Please enter your email';
                            }
                            // Stricter regex to prevent overly simple/invalid emails like a@h.com
                            final regex = RegExp(
                              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
                            );
                            if (!regex.hasMatch(email)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.s),
                        AppInputField(
                          controller: _passwordController,
                          hint: AppStrings.passwordHint,
                          prefixIcon: Icons.lock_outline,
                          isObscure: true,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: AppText.caption(
                              AppStrings.forgotPassword,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        BlocConsumer<LoginBloc, LoginState>(
                          listener: (context, state) {
                            if (state is LoginFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: errorColor,
                                ),
                              );
                            }

                            if (state is LoginSuccess) {
                              context.read<AuthBloc>().add(
                                LoggedIn(
                                  id: state.id,
                                  role: state.role,
                                  guideRequestStatus: state.guideRequestStatus,
                                  name: state.name,
                                  email: state.email,
                                  tripsCount: state.tripsCount,
                                  savedCount: state.savedCount,
                                  reviewsCount: state.reviewsCount,
                                  postsCount: state.postsCount,
                                ),
                              );
                              Navigator.pushReplacementNamed(
                                context,
                                RouteNames.home,
                              );
                            }
                          },
                          builder: (context, state) {
                            return AppButton(
                              text: AppStrings.loginBtn,
                              isLoading: state is LoginLoading,
                              onPressed: _submit,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText.caption(AppStrings.noAccountPrompt),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, RouteNames.signup);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                              child: AppText.caption(
                                AppStrings.signupLink,
                                color: primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
