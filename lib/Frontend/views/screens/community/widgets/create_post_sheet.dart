import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/services/post_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_event.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import '../../../../core/widgets/custom_toast.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _postService = PostService();
  final _picker = ImagePicker();
  List<XFile> _imageFiles = [];
  bool _isLoading = false;
  bool _isPickerActive = false;

  Future<void> _pickImages() async {
    if (_isPickerActive) return;

    if (_imageFiles.length >= 10) {
      CustomToast.warning(context, "Maximum 10 images allowed");
      return;
    }

    setState(() => _isPickerActive = true);
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          int remaining = 10 - _imageFiles.length;
          _imageFiles.addAll(pickedFiles.take(remaining));
        });
      }
    } catch (e) {
      debugPrint("Image picking error: $e");
    } finally {
      if (mounted) setState(() => _isPickerActive = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (_captionController.text.isEmpty || _locationController.text.isEmpty) {
      CustomToast.warning(context, AppStrings.commFillFieldsError);
      return;
    }

    if (_imageFiles.isEmpty) {
      CustomToast.warning(context, AppStrings.commUploadImageError);
      return;
    }

    setState(() => _isLoading = true);

    final success = await _postService.createPost(
      location: _locationController.text,
      caption: _captionController.text,
      imageFiles: _imageFiles,
    );

    setState(() => _isLoading = false);

    if (success != null) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          context.read<AuthBloc>().add(
            UpdateAuthCounts(postsCount: authState.postsCount + 1),
          );
        }
        CustomToast.success(context, "Post created successfully!");
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        CustomToast.error(context, AppStrings.commCreatePostFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.ms,
        right: AppSpacing.ms,
        top: AppSpacing.m,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                AppStrings.commCreateHeading,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _locationController,
              label: AppStrings.commLocationLabel,
              icon: Icons.location_on_rounded,
              hint: AppStrings.commLocationHint,
            ),
            const SizedBox(height: 20),
            AppText.body(
              AppStrings.commPhotoLabel,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount:
                    _imageFiles.length + (_imageFiles.length < 10 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _imageFiles.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: primaryBlue.withOpacity(0.5),
                            ),
                            const SizedBox(height: 4),
                            AppText.caption("Add Photo", color: primaryBlue),
                          ],
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(File(_imageFiles[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _captionController,
              label: AppStrings.commCaptionLabel,
              icon: Icons.notes,
              hint: AppStrings.commCaptionHint,
              minLines: 1,
              maxLines: null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      AppStrings.commPostBtn,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int minLines = 1,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryBlue),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
