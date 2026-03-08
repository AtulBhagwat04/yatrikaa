import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/services/post_service.dart';
import 'package:bhatkanti_app/Frontend/core/models/post_model.dart';
import 'package:bhatkanti_app/Frontend/core/widgets/custom_toast.dart';

class EditPostSheet extends StatefulWidget {
  final PostModel post;
  const EditPostSheet({super.key, required this.post});

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  late TextEditingController _captionController;
  late TextEditingController _locationController;
  final _postService = PostService();
  final _picker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;
  bool _isPickerActive = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.caption);
    _locationController = TextEditingController(text: widget.post.location);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickerActive) return;

    setState(() => _isPickerActive = true);
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint("Image picking error: $e");
    } finally {
      if (mounted) setState(() => _isPickerActive = false);
    }
  }

  Future<void> _updatePost() async {
    if (_captionController.text.isEmpty || _locationController.text.isEmpty) {
      CustomToast.warning(context, AppStrings.commFillFieldsError);
      return;
    }

    setState(() => _isLoading = true);

    final updatedPost = await _postService.updatePost(
      postId: widget.post.id,
      location: _locationController.text,
      caption: _captionController.text,
      imageFile: _imageFile,
    );

    setState(() => _isLoading = false);

    if (updatedPost != null) {
      if (mounted) {
        CustomToast.success(context, "Post updated successfully!");
        Navigator.pop(context, updatedPost);
      }
    } else {
      if (mounted) {
        CustomToast.error(context, "Failed to update post");
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
                "Edit Your Journey",
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
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(File(_imageFile!.path)),
                          fit: BoxFit.cover,
                        )
                      : DecorationImage(
                          image: NetworkImage(widget.post.imageUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _imageFile == null
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 30,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            AppText.caption(
                              "Tap to change photo",
                              color: Colors.white,
                            ),
                          ],
                        ),
                      )
                    : null,
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
              onPressed: _isLoading ? null : _updatePost,
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
                      "Save Changes",
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
