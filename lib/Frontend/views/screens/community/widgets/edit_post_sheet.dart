import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/services/post_service.dart';
import 'package:yatrikaa/Frontend/core/models/post_model.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_location_field.dart';


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
  final List<XFile> _imageFiles = [];
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

  Future<void> _pickImages() async {
    if (_isPickerActive) return;

    setState(() => _isPickerActive = true);
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(pickedFiles);
        });
      }
    } catch (e) {
      debugPrint("Image picking error: $e");
    } finally {
      if (mounted) setState(() => _isPickerActive = false);
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
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
      imageFiles: _imageFiles,
    );

    setState(() => _isLoading = false);

    if (updatedPost != null) {
      if (mounted) {
        CustomToast.success(context, "Post updated successfully!");
        Navigator.of(context).pop(updatedPost);
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
            Column(
              children: [
                Text(
                  "Edit Your Journey",
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: appBlack,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ModernLocationField(
              controller: _locationController,
              label: AppStrings.commLocationLabel,
              hint: AppStrings.commLocationHint,
              onSelected: (place) {
                setState(() => _locationController.text = place.name);
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.body(
                  AppStrings.commPhotoLabel,
                  fontWeight: FontWeight.w700,
                ),
                AppText.caption(
                  "${widget.post.images.length + _imageFiles.length} / 10",
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Show existing images
                  ...widget.post.images.map(
                    (url) => Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Show newly picked images
                  ..._imageFiles.asMap().entries.map(
                    (entry) => Stack(
                      children: [
                        Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: FileImage(File(entry.value.path)),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 18,
                          child: GestureDetector(
                            onTap: () => _removeNewImage(entry.key),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.black45,
                                child: const Icon(
                                  Icons.close,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add more button
                  if (_imageFiles.length + widget.post.images.length < 10)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 110,
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryBlue.withValues(alpha: 0.1),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo_rounded,
                                color: primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Add",
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? () {} : _updatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor:
                      primaryBlue, // Keep color during loading
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
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
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontWeight: FontWeight.w700),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: minLines,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: appGrey.withValues(alpha: 0.6), fontSize: 14),
            prefixIcon: Icon(icon, color: primaryBlue, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: appGreyVeryLight.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: appGreyLight.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: appGreyLight.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
