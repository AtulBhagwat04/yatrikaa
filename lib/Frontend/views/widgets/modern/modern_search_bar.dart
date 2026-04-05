import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';

class ModernSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autoFocus;
  final FocusNode? focusNode;

  const ModernSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.autoFocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: appGreyLight.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        focusNode: focusNode,
        autofocus: autoFocus,
        readOnly: onTap != null,
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          hintStyle: TextStyle(
            color: appGrey.withOpacity(0.6),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(Icons.search, color: primaryBlue, size: 22),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller!.clear();
                    if (onChanged != null) onChanged!("");
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: appGrey,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
