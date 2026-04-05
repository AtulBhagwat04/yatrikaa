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
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/sign_up_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/sign_up_event.dart';
import 'package:yatrikaa/Frontend/views/screens/auth/bloc/sign_up_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'user';
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    setState(() {
      _autoValidateMode = AutovalidateMode.always;
    });

    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<SignupBloc>().add(
        SignupSubmitted(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
        ),
      );
    }
  }

  Widget _buildRoleSelector() {
    final roles = [
      {'value': 'user', 'label': 'Traveler', 'icon': Icons.people_alt_rounded},
      {'value': 'guide', 'label': 'Guide', 'icon': Icons.person_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.s),
          child: AppText.caption(
            "Joining as",
            fontWeight: FontWeight.w700,
            color: appBlack.withOpacity(0.7),
          ),
        ),
        Row(
          children: roles.map((role) {
            final isSelected = _selectedRole == role['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedRole = role['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(
                    right: role['value'] == 'user' ? AppSpacing.xs : 0,
                    left: role['value'] == 'guide' ? AppSpacing.xs : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryBlue
                        : onboardingBlueVeryLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryBlue
                          : primaryBlue.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        role['icon'] as IconData,
                        color: isSelected ? appWhite : primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      AppText.caption(
                        role['label'] as String,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? appWhite : primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (_) => SignupBloc(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [onboardingBlueVeryLight, onboardingBlueLight],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: BlocConsumer<SignupBloc, SignupState>(
                listener: (context, state) {
                  if (state is SignupSuccess) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                AppStrings.signupSuccessMsg,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(AppSpacing.m),
                      ),
                    );
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
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.home,
                      (route) => false,
                    );
                  }
                },
                builder: (context, state) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autoValidateMode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: size.height * 0.15),
                            AppText.heading(
                              AppStrings.createAccount,
                              align: TextAlign.left,
                            ),
                            const SizedBox(height: AppSpacing.s),
                            AppText.body(
                              AppStrings.signupSubtitle,
                              align: TextAlign.left,
                            ),
                            const SizedBox(height: AppSpacing.l),

                            /// In-form Error Message
                            if (state is SignupFailure)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.m,
                                ),
                                decoration: BoxDecoration(
                                  color: errorColorLight.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: errorColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: errorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: AppText.caption(
                                        state.message,
                                        color: errorColorDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            AppInputField(
                              controller: _nameController,
                              hint: AppStrings.fullNameHint,
                              prefixIcon: Icons.person_rounded,
                              focusNode: _nameFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(
                                context,
                              ).requestFocus(_emailFocus),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (name.length < 3) {
                                  return 'Please enter at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.s),
                            AppInputField(
                              controller: _emailController,
                              hint: AppStrings.emailHint,
                              prefixIcon: Icons.email_rounded,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
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
                              prefixIcon: Icons.lock_rounded,
                              isObscure: true,
                              focusNode: _passwordFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.m),
                            _buildRoleSelector(),
                            const SizedBox(height: AppSpacing.l),
                            AppButton(
                              text: AppStrings.signupBtn,
                              isLoading: state is SignupLoading,
                              onPressed: () => _submit(context),
                            ),

                            const SizedBox(height: AppSpacing.m),

                            /// Footer Links
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText.caption(
                                  'Already have an account?',
                                  color: appBlack.withOpacity(0.6),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  child: AppText.caption(
                                    'Log In',
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
