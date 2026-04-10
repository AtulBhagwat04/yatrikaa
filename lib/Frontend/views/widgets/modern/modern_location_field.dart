import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/models/place_model.dart';
import 'package:yatrikaa/Frontend/core/services/places_service.dart';

class ModernLocationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Function(PlaceModel)? onSelected;
  final String? Function(String?)? validator;

  final bool showLabel;
  final bool isDense;

  const ModernLocationField({
    super.key,
    required this.controller,
    this.label = "",
    required this.hint,
    this.icon = Icons.location_on_rounded,
    this.onSelected,
    this.validator,
    this.showLabel = true,
    this.isDense = false,
  });

  @override
  State<ModernLocationField> createState() => _ModernLocationFieldState();
}

class _ModernLocationFieldState extends State<ModernLocationField> {
  final PlacesService _placesService = PlacesService();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  List<PlaceModel> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty || !mounted) return;
      
      setState(() => _isSearching = true);
      _showOverlay(); // Show loading overlay
      
      try {
        final results = await _placesService.searchPlaces(query);
        if (mounted) {
          // Verify that input hasn't been cleared while searching
          if (widget.controller.text.trim().isEmpty) {
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
            _showOverlay(); // Refresh overlay with results
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

  void _showOverlay() {
    _removeOverlay();
    
    if (!mounted) return;
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
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: appGreyVeryLight,
                      ),
                      itemBuilder: (context, index) {
                        final place = _suggestions[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: primaryBlue,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            place.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            place.formattedAddress ?? "Maharashtra, India",
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: appGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            widget.controller.text = place.name;
                            widget.onSelected?.call(place);
                            setState(() => _suggestions = []);
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
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLabel && widget.label.isNotEmpty) ...[
            Text(
              widget.label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: appBlack,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: widget.controller,
            onChanged: _onChanged,
            validator: widget.validator,
            style: GoogleFonts.montserrat(
              fontSize: widget.isDense ? 12 : 14,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.montserrat(
                color: appGreyLight,
                fontSize: widget.isDense ? 11 : 14,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: primaryBlue,
                size: widget.isDense ? 14 : 20,
              ),
              isDense: widget.isDense,
              suffixIcon: _isSearching
                  ? Padding(
                      padding: EdgeInsets.all(widget.isDense ? 8 : 12),
                      child: SizedBox(
                        height: widget.isDense ? 12 : 16,
                        width: widget.isDense ? 12 : 16,
                        child: CircularProgressIndicator(
                          strokeWidth: widget.isDense ? 1.5 : 2,
                        ),
                      ),
                    )
                  : widget.controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: widget.isDense ? 14 : 20,
                          ),
                          onPressed: () {
                            widget.controller.clear();
                            setState(() => _suggestions = []);
                            _removeOverlay();
                          },
                        )
                      : null,
              filled: true,
              fillColor: widget.isDense
                  ? Colors.black.withOpacity(0.04)
                  : appGreyVeryLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isDense ? 8 : 12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isDense ? 8 : 12),
                borderSide: const BorderSide(color: primaryBlue, width: 1.5),
              ),
              contentPadding: widget.isDense
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
