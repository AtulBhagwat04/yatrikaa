import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_button.dart';
import '../../../core/constants/app_input_fields.dart';
import '../../Routes/route_names.dart';
import 'bloc/login_bloc.dart';
import 'bloc/login_event.dart';
import 'bloc/login_state.dart';

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

  late LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();

    _loginBloc = LoginBloc();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

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
    FocusScope.of(context).unfocus();

    _loginBloc.add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
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
              colors: [
                onboardingBlueVeryLight,
                onboardingBlueLight,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                bottom:
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: size.height * 0.2),

                      AppText.heading(
                        'Welcome back',
                        align: TextAlign.left,
                      ),

                      const SizedBox(height: AppSpacing.s),

                      AppText.body(
                        'Login to continue your journey with us.',
                        align: TextAlign.left,
                      ),

                      const SizedBox(height: AppSpacing.l),

                      AppInputField(
                        controller: _emailController,
                        hint: 'Email',
                        prefixIcon: Icons.email_outlined,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context)
                                .requestFocus(_passwordFocus),
                      ),

                      const SizedBox(height: AppSpacing.s),

                      AppInputField(
                        controller: _passwordController,
                        hint: 'Password',
                        prefixIcon: Icons.lock_outline,
                        isObscure: true,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: AppText.caption(
                            'Forgot password?',
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
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                        builder: (context, state) {
                          return AppButton(
                            text: 'LOGIN',
                            isLoading: state is LoginLoading,
                            onPressed: _submit,
                          );

                        },
                      ),

                      const SizedBox(height: AppSpacing.m),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText.caption('Don’t have an account? '),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RouteNames.signup,
                              );
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
                              'Sign Up',
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
    );
  }
}
