import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool isObscure;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final int maxLines;
  final EdgeInsetsGeometry? contentPadding;

  const AppInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.isObscure = false,
    this.focusNode,
    this.textInputAction,
    this.keyboardType,
    this.onFieldSubmitted,
    this.validator,
    this.maxLines = 1,
    this.contentPadding,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _obscureText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isObscure;

    widget.focusNode?.addListener(() {
      setState(() {
        _isFocused = widget.focusNode!.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4), // Space for error text
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscureText,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        maxLines: widget.maxLines,
        cursorColor: primaryBlue,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: appBlack.withOpacity(0.4),
            fontWeight: FontWeight.w400,
          ),

          /// Prefix Icon
          prefixIcon: Icon(widget.prefixIcon, color: primaryBlue),

          /// 👁 Password Toggle
          suffixIcon: widget.isObscure
              ? IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: primaryBlue,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,

          filled: true,
          fillColor: primaryWhite,

          contentPadding: widget.contentPadding ??
              const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),

          /// Default Border
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: onboardingBlueSoft, width: 1.2),
          ),

          /// Enabled Border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: onboardingBlueSoft, width: 1.2),
          ),

          /// Focus Border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.8),
          ),

          /// Error Borders
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
// git hub login