import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/app_input_fields.dart';
import 'package:yatrikaa/Frontend/core/constants/app_button.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await _authService.changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

        if (mounted) {
          CustomToast.success(context, 'Password updated successfully');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          CustomToast.error(context, e.toString().replaceAll('Exception: ', ''));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [onboardingBlueVeryLight, onboardingBlueLight, appWhite],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // --- Custom App Bar ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Center(
                  child: AppText.subHeading(
                    'Change Password',
                    color: appBlack,
                    fontWeight: FontWeight.w900,
                    size: 20,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        const SizedBox(height: 20),

                        // --- Form Container (Elegant Card) ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: appWhite,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.03),
                                blurRadius: 10,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Field: Current Password ---
                              _buildFieldLabel('Current Password'),
                              AppInputField(
                                controller: _currentPasswordController,
                                hint: 'Enter current password',
                                prefixIcon: Icons.lock_outline_rounded,
                                isObscure: true,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Current password is required'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.s),

                              // --- Field: New Password ---
                              _buildFieldLabel('New Password'),
                              AppInputField(
                                controller: _newPasswordController,
                                hint: 'At least 6 characters',
                                prefixIcon: Icons.lock_reset_rounded,
                                isObscure: true,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'New password is required';
                                  }
                                  if (val.length < 6) {
                                    return 'Minimum 6 characters required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.s),

                              // --- Field: Confirm Password ---
                              _buildFieldLabel('Confirm New Password'),
                              AppInputField(
                                controller: _confirmPasswordController,
                                hint: 'Retype new password',
                                prefixIcon: Icons.lock_clock_outlined,
                                isObscure: true,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  if (val != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.m),

                        // --- Centered "Update Password" Button ---
                        Center(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: AppButton(
                              text: 'Update Password',
                              isLoading: _isLoading,
                              onPressed: _changePassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: AppText.body(
        label,
        fontWeight: FontWeight.w700,
        color: appBlack.withOpacity(0.8),
        size: 14,
      ),
    );
  }
}
