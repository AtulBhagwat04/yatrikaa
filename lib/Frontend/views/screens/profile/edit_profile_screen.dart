import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_input_fields.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_button.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_event.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController = TextEditingController(text: authState.name);
      _emailController = TextEditingController(text: authState.email);
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final data = await _authService.updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );

        if (mounted) {
          final currentAuthState = context.read<AuthBloc>().state;
          final int currentPostsCount = currentAuthState is Authenticated
              ? currentAuthState.postsCount
              : 0;

          context.read<AuthBloc>().add(
            LoggedIn(
              id:
                  (data['id'] ??
                          (currentAuthState is Authenticated
                              ? currentAuthState.id
                              : ''))
                      .toString(),
              role:
                  (data['role'] ??
                          (currentAuthState is Authenticated
                              ? currentAuthState.role
                              : 'user'))
                      .toString(),
              name:
                  (data['name'] ??
                          (currentAuthState is Authenticated
                              ? currentAuthState.name
                              : ''))
                      .toString(),
              email:
                  (data['email'] ??
                          (currentAuthState is Authenticated
                              ? currentAuthState.email
                              : ''))
                      .toString(),
              tripsCount:
                  (data['tripsCount'] as num?)?.toInt() ??
                  (currentAuthState is Authenticated
                      ? currentAuthState.tripsCount
                      : 0),
              savedCount:
                  (data['savedCount'] as num?)?.toInt() ??
                  (currentAuthState is Authenticated
                      ? currentAuthState.savedCount
                      : 0),
              reviewsCount:
                  (data['reviewsCount'] as num?)?.toInt() ??
                  (currentAuthState is Authenticated
                      ? currentAuthState.reviewsCount
                      : 0),
              postsCount:
                  (data['postsCount'] as num?)?.toInt() ?? currentPostsCount,
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: successColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: errorColor,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: appBlack,
            size: 20,
          ),
        ),
        title: AppText.subHeading(
          'Edit Profile',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        child: AppText.heading(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : '?',
                          color: primaryBlue,
                          size: 32,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryBlue,
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppText.body('Full Name', fontWeight: FontWeight.bold),
              const SizedBox(height: AppSpacing.xs),
              AppInputField(
                controller: _nameController,
                hint: 'Enter your name',
                prefixIcon: Icons.person_outline,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.m),
              AppText.body('Email Address', fontWeight: FontWeight.bold),
              const SizedBox(height: AppSpacing.xs),
              AppInputField(
                controller: _emailController,
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  final email = val?.trim() ?? '';
                  if (email.isEmpty) return 'Email is required';
                  final regex = RegExp(
                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
                  );
                  if (!regex.hasMatch(email)) return 'Invalid email address';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _updateProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
