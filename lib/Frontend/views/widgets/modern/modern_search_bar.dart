import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';

class ModernSearchBar extends StatefulWidget {
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
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar> {
  Timer? _typingTimer;
  Timer? _cyclingTimer;
  int _hintIndex = 0;
  String _displayText = "";
  int _charIndex = 0;

  final List<String> _hints = [
    "Where do you want to go?",
    "Find your next adventure...",
    "Explore hidden gems?",
    "Discover amazing packages",
    "Where to next, explorer?",
    "Search any destination",
    "Ready for a weekend getaway?",
    "Discover historical landmarks",
    "Find the best beach resorts...",
    "Looking for a mountain retreat?",
    "Plan your dream itinerary",
    "Search for group trips!",
    "Find activities near you...",
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _cyclingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _hintIndex = (_hintIndex + 1) % _hints.length;
          _displayText = "";
          _charIndex = 0;
          _typingTimer?.cancel();
          _startTyping();
        });
      }
    });
    _startTyping(); // Start first one immediately
  }

  void _startTyping() {
    final targetText = _hints[_hintIndex];
    _typingTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (mounted && _charIndex < targetText.length) {
        setState(() {
          _displayText = targetText.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        _typingTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cyclingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: primaryBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: onboardingBlueSoft, width: 1),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        focusNode: widget.focusNode,
        autofocus: widget.autoFocus,
        readOnly: widget.onTap != null,
        decoration: InputDecoration(
          hintText: _displayText,
          hintStyle: TextStyle(
            color: appGrey.withOpacity(0.6),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(Icons.search, color: primaryBlue, size: 22),
          suffixIcon:
              widget.controller != null && widget.controller!.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    widget.controller!.clear();
                    if (widget.onChanged != null) widget.onChanged!("");
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
