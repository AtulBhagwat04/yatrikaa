import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/app_button.dart';
import 'package:yatrikaa/Frontend/core/constants/app_input_fields.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_event.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/login_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/login_event.dart';
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/login_state.dart';

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
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

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
    setState(() {
      _autoValidateMode = AutovalidateMode.always;
    });

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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlocProvider.value(
        value: _loginBloc,
        child: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is ForgotPasswordSuccess) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                child: Dialog(
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Form(
                        key: dialogFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: AppSpacing.m),
                            AppText.heading(
                              "Reset Password",
                              fontWeight: FontWeight.w800,
                            ),
                            const SizedBox(height: AppSpacing.s),

                            AppText.body(
                              "Enter your email to receive a password reset link.",
                              color: Colors.grey.shade600,
                              size: 14,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppInputField(
                              controller: emailController,
                              hint: 'Email Address',
                              prefixIcon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.l),
                            AppButton(
                              text: 'Send Reset Link',
                              isLoading: state is ForgotPasswordLoading,
                              onPressed: () {
                                if (dialogFormKey.currentState?.validate() ??
                                    false) {
                                  _loginBloc.add(
                                    ForgotPasswordRequested(
                                      emailController.text.trim(),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
                    autovalidateMode: _autoValidateMode,
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
                            final regex = RegExp(
                              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
                            );
                            if (!regex.hasMatch(email)) {
                              return 'Please enter a valid email';
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
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: AppText.caption(
                              AppStrings.forgotPassword,
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        BlocConsumer<LoginBloc, LoginState>(
                          listener: (context, state) {
                            if (state is LoginFailure) {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          state.message,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: errorColorDark,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(AppSpacing.m),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }

                            if (state is ForgotPasswordSuccess &&
                                ModalRoute.of(context)?.isCurrent == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: successColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
