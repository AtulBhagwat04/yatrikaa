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
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/sign_up_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/sign_up_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/auth/bloc/sign_up_state.dart';

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String _selectedRole = 'user';

  void _submit(BuildContext context) {
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
      {'value': 'user', 'label': 'Traveler', 'icon': Icons.people_alt_outlined},
      {'value': 'guide', 'label': 'Guide', 'icon': Icons.person_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs + 2),
          child: AppText.body(
            "Joining as",
            fontWeight: FontWeight.bold,
            color: appBlack,
            letterSpacing: 0.3,
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
                        : primaryWhite.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        role['icon'] as IconData,
                        color: isSelected ? Colors.white : primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      AppText.body(
                        role['label'] as String,
                        size: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : primaryBlue,
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
                          AppStrings.createAccount,
                          align: TextAlign.left,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        AppText.body(
                          AppStrings.signupSubtitle,
                          align: TextAlign.left,
                        ),
                        const SizedBox(height: AppSpacing.l),
                        AppInputField(
                          controller: _nameController,
                          hint: AppStrings.fullNameHint,
                          prefixIcon: Icons.person_outline,
                          focusNode: _nameFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (name.length < 2) {
                              return 'Name is too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.s),
                        AppInputField(
                          controller: _emailController,
                          hint: AppStrings.emailHint,
                          prefixIcon: Icons.email_outlined,
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
                        const SizedBox(height: AppSpacing.s),
                        _buildRoleSelector(),
                        const SizedBox(height: AppSpacing.l),
                        BlocConsumer<SignupBloc, SignupState>(
                          listener: (context, state) {
                            if (state is SignupFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );
                            }

                            if (state is SignupSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.signupSuccessMsg),
                                ),
                              );
                              context.read<AuthBloc>().add(
                                LoggedIn(
                                  role: state.role,
                                  name: state.name,
                                  email: state.email,
                                  tripsCount: state.tripsCount,
                                  savedCount: state.savedCount,
                                  reviewsCount: state.reviewsCount,
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
                            return AppButton(
                              text: AppStrings.signupBtn,
                              isLoading: state is SignupLoading,
                              onPressed: state is SignupLoading
                                  ? null
                                  : () => _submit(context),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.l),
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
