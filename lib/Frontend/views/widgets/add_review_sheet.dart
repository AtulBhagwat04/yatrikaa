import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';

class AddReviewSheet extends StatefulWidget {
  final String id;
  final bool isPackage;
  final double? initialRating;
  final String? initialComment;
  final Function(double rating, String comment) onSubmitted;

  const AddReviewSheet({
    super.key,
    required this.id,
    required this.onSubmitted,
    this.isPackage = false,
    this.initialRating,
    this.initialComment,
  });

  @override
  State<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  late double _rating;
  late final TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _commentController = TextEditingController(text: widget.initialComment ?? "");
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_rating == 0) {
      CustomToast.error(context, 'Please provide a rating');
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      CustomToast.error(context, 'Please write a review comment');
      return;
    }

    if (comment.length < 2) {
      CustomToast.error(context, 'Review must be at least 2 characters');
      return;
    }

    setState(() => _isSubmitting = true);
    await widget.onSubmitted(_rating, _commentController.text.trim());
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              AppText.subHeading(
                widget.initialRating != null
                    ? 'Update your review'
                    : (widget.isPackage ? 'How was your trip?' : 'How was this place?'),
                fontWeight: FontWeight.w900,
                size: 20,
              ),
              const SizedBox(height: 4),
              AppText.caption(
                widget.initialRating != null
                    ? 'Refine your thoughts and rating'
                    : 'Rate and share your experiences',
                color: Colors.grey[500],
              ),
              const SizedBox(height: 24),
              
              // Animated Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isSelected = index < _rating;
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: IconButton(
                      onPressed: () => setState(() => _rating = index + 1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: isSelected ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 8),
              _getRatingLabel(),
              const SizedBox(height: 24),
              
              // Comment Field
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
                style: GoogleFonts.outfit(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'What did you like the most?',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[100]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.initialRating != null ? 'Update Review' : 'Submit Review',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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

  Widget _getRatingLabel() {
    if (_rating == 0) return const SizedBox.shrink();
    
    final labels = ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent!'];
    final colors = [Colors.red, Colors.orange, Colors.blue, Colors.green, primaryBlue];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors[_rating.toInt() - 1].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[_rating.toInt() - 1],
        style: GoogleFonts.outfit(
          color: colors[_rating.toInt() - 1],
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
