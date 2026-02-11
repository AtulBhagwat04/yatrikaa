import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bhatkanti_app/Frontend/core/constants/colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_button.dart';
import '../../../core/constants/app_input_fields.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  AnimationController? _controller;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic),
    );

    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();

    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (_) => LoginBloc(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 6000),
          curve: Curves.easeInOut,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: AppSpacing.l,
                    right: AppSpacing.l,
                    bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
                  ),
                  child: ConstrainedBox(
                    constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                    child: FadeTransition(
                      opacity: _fadeAnimation!,
                      child: SlideTransition(
                        position: _slideAnimation!,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: size.height * 0.2),

                            /// Title
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

                            /// Email
                            AppInputField(
                              controller: _emailController,
                              hint: 'Email',
                              prefixIcon: Icons.email_outlined,
                              focusNode: _emailFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_passwordFocus);
                              },
                            ),

                            const SizedBox(height: AppSpacing.s),

                            /// Password
                            AppInputField(
                              controller: _passwordController,
                              hint: 'Password',
                              prefixIcon: Icons.lock_outline,
                              isObscure: true,
                              focusNode: _passwordFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  _submit(context),
                            ),

                            const SizedBox(height: AppSpacing.xs),

                            /// Forgot Password
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

                            /// Login Button With Bloc
                            BlocConsumer<LoginBloc, LoginState>(
                              listener: (context, state) {
                                if (state is LoginSuccess) {
                                  debugPrint("Login Success");
                                  // Navigator.pushReplacementNamed(context, '/home');
                                }

                                if (state is LoginFailure) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(state.message),
                                    ),
                                  );
                                }
                              },
                              builder: (context, state) {
                                return AppButton(
                                  text: 'LOGIN',
                                  isLoading:
                                  state is LoginLoading,
                                  onPressed: state is LoginLoading
                                      ? null
                                      : () => _submit(context),
                                );
                              },
                            ),

                            const SizedBox(height: AppSpacing.m),

                            /// Signup
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText.caption(
                                    'Don’t have an account? '),
                                GestureDetector(
                                  onTap: () {},
                                  child: AppText.caption(
                                    'Sign up',
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.l),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
