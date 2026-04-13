import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/app_input_fields.dart';
import 'package:yatrikaa/Frontend/core/constants/app_button.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_event.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedGender;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _existingProfilePicture;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController = TextEditingController(text: authState.name);
      _emailController = TextEditingController(text: authState.email);
      _phoneController = TextEditingController(
        text: authState.phoneNumber ?? '',
      );
      _selectedGender = authState.gender ?? 'Prefer not to say';
      _existingProfilePicture = authState.profilePicture;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _selectedGender = 'Prefer not to say';
    }
  }

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (selected != null) {
      setState(() {
        _imageFile = selected;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final data = await _authService.updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          gender: _selectedGender,
          profileImage: _imageFile,
        );

        if (mounted) {
          final currentAuthState = context.read<AuthBloc>().state;
          final current = currentAuthState is Authenticated
              ? currentAuthState
              : null;

          context.read<AuthBloc>().add(
            LoggedIn(
              id: (data['id'] ?? current?.id ?? '').toString(),
              role: (data['role'] ?? current?.role ?? 'user').toString(),
              name: (data['name'] ?? current?.name ?? '').toString(),
              email: (data['email'] ?? current?.email ?? '').toString(),
              tripsCount:
                  (data['tripsCount'] as num?)?.toInt() ??
                  current?.tripsCount ??
                  0,
              savedCount:
                  (data['savedCount'] as num?)?.toInt() ??
                  current?.savedCount ??
                  0,
              reviewsCount:
                  (data['reviewsCount'] as num?)?.toInt() ??
                  current?.reviewsCount ??
                  0,
              postsCount:
                  (data['postsCount'] as num?)?.toInt() ??
                  current?.postsCount ??
                  0,
              phoneNumber:
                  data['phoneNumber']?.toString() ?? current?.phoneNumber,
              gender: data['gender']?.toString() ?? current?.gender,
              profilePicture:
                  data['profilePicture']?.toString() ?? current?.profilePicture,
            ),
          );

          CustomToast.success(context, 'Profile updated successfully');
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
                    'Edit Profile',
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

                        // --- Centered Avatar (Compact & Elegant) ---
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 135,
                                  height: 135,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: onboardingBlueDark.withValues(alpha: 0.2,),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: appWhite,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Stack(
                                      children: [
                                        // Current/New Image
                                        Positioned.fill(
                                          child: _imageFile != null
                                              ? Image.file(
                                                  File(_imageFile!.path),
                                                  fit: BoxFit.cover,
                                                )
                                              : _existingProfilePicture !=
                                                        null &&
                                                    _existingProfilePicture!
                                                        .isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      _existingProfilePicture!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  primaryBlue,
                                                            ),
                                                      ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          _buildPlaceholderAvatar(),
                                                )
                                              : _buildPlaceholderAvatar(),
                                        ),
                                        // "Edit" Centered Overlay
                                        Container(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          child: const Center(
                                            child: Icon(
                                              Icons.camera_alt,
                                              color: appWhite,
                                              size: 32,
                                            ),
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

                        const SizedBox(height: AppSpacing.ml),

                        // --- Input Form Container (Elegant & Visible Card) ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: appWhite,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.03),
                                blurRadius: 10,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Field: Name ---
                              _buildFieldLabel('Full Name'),
                              AppInputField(
                                controller: _nameController,
                                hint: 'e.g. Melissa Peters',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.s),

                              // --- Field: Email ---
                              _buildFieldLabel('Email Address'),
                              AppInputField(
                                controller: _emailController,
                                hint: 'e.g. melissa@example.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  final email = val?.trim() ?? '';
                                  if (email.isEmpty) return 'Email is required';
                                  final regex = RegExp(
                                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
                                  );
                                  if (!regex.hasMatch(email)) {
                                    return 'Invalid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.s),

                              // --- Field: Phone ---
                              _buildFieldLabel('Phone Number'),
                              AppInputField(
                                controller: _phoneController,
                                hint: '+91 1234567890',
                                prefixIcon: Icons.call,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: AppSpacing.s),

                              // --- Field: Gender ---
                              _buildFieldLabel('Gender'),
                              _buildGenderDropdown(),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.m),

                        // --- Centered "Save changes" Button ---
                        Center(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: AppButton(
                              text: 'Save changes',
                              isLoading: _isLoading,
                              onPressed: _updateProfile,
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
        color: appBlack.withValues(alpha: 0.8),
        size: 14,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onboardingBlueSoft.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: appGrey),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: appBlack,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((
            String value,
          ) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return CircleAvatar(
      backgroundColor: onboardingBlueVeryLight,
      child: AppText.heading(
        _nameController.text.isNotEmpty
            ? _nameController.text[0].toUpperCase()
            : '?',
        color: primaryBlue,
        size: 42,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
