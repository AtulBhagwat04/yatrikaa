import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/services/places_service.dart';
import 'package:yatrikaa/Frontend/core/services/packages_service.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';

enum SuggestionType { places, packages }

class ModernSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autoFocus;
  final FocusNode? focusNode;
  final bool suggestionsEnabled;
  final SuggestionType suggestionType;
  final Function(String)? onSuggestionSelected;
  final IconData? icon;
  final String? hint;

  const ModernSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.autoFocus = false,
    this.focusNode,
    this.suggestionsEnabled = false,
    this.suggestionType = SuggestionType.places,
    this.onSuggestionSelected,
    this.icon,
    this.hint,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar> {
  final PlacesService _placesService = PlacesService();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _isSearching = false;

  Timer? _typingTimer;
  Timer? _cyclingTimer;
  Timer? _searchTimer;
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
    "Adventure is calling you!",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.hint == null) {
      _startHintCycling();
    } else {
      _displayText = widget.hint!;
    }
  }

  void _startHintCycling() {
    _displayText = "";
    _charIndex = 0;
    _cycleHint();
  }

  void _cycleHint() {
    if (!mounted || widget.hint != null) return;

    final currentHint = _hints[_hintIndex];
    if (_charIndex < currentHint.length) {
      setState(() {
        _displayText = currentHint.substring(0, _charIndex + 1);
        _charIndex++;
      });
      _typingTimer = Timer(const Duration(milliseconds: 50), _cycleHint);
    } else {
      _cyclingTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted || widget.hint != null) return;
        setState(() {
          _hintIndex = (_hintIndex + 1) % _hints.length;
          _charIndex = 0;
          _displayText = "";
        });
        _cycleHint();
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cyclingTimer?.cancel();
    _searchTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onChanged(String value) {
    if (widget.onChanged != null) widget.onChanged!(value);

    if (!widget.suggestionsEnabled) return;

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      _showOverlay(); // Show loading state

      try {
        final List<String> results = await _fetchSuggestions(value);
        if (mounted) {
          // Double check that the input hasn't been cleared while we were waiting
          if (widget.controller?.text.trim().isEmpty ?? true) {
            setState(() {
              _suggestions = [];
              _isSearching = false;
            });
            _removeOverlay();
            return;
          }

          setState(() {
            _suggestions = results;
            _isSearching = false;
          });

          if (_suggestions.isEmpty) {
            _removeOverlay();
          } else {
            _showOverlay();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
          _removeOverlay();
        }
      }
    });
  }

  Future<List<String>> _fetchSuggestions(String query) async {
    if (widget.suggestionType == SuggestionType.packages) {
      final packagesService = PackagesService();
      final result = await packagesService.getPackagesPaginated(search: query);
      final List<TravelPackageModel> packages = result['packages'] ?? [];
      return packages.map((p) => p.title).toList();
    } else {
      final places = await _placesService.searchPlaces(query);
      return places.map((p) => p.name).toList();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (!widget.suggestionsEnabled || !mounted) return;
    if (_suggestions.isEmpty && !_isSearching) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryBlue.withOpacity(0.1)),
              ),
              child: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: Icon(
                            widget.suggestionType == SuggestionType.places
                                ? Icons.place_rounded
                                : Icons.backpack_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                          title: Text(
                            suggestion,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            if (widget.controller != null) {
                              widget.controller!.text = suggestion;
                            }
                            widget.onSuggestionSelected?.call(suggestion);
                            _removeOverlay();
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
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
          onChanged: _onChanged,
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
            prefixIcon: Icon(
              widget.icon ?? Icons.search,
              color: primaryBlue,
              size: 22,
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller != null &&
                      widget.controller!.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      widget.controller!.clear();
                      if (widget.onChanged != null) widget.onChanged!("");
                      _removeOverlay();
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
      ),
    );
  }
}
