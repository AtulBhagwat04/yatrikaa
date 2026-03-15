import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/services/packages_service.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';

/// Screen for guides / admins to create a new travel package.
/// All data is submitted to the backend via [PackagesService].
class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final PackagesService _service = PackagesService();
  bool _isSubmitting = false;

  // ── Basic Info ────────────────────────────────────────────────────────────
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _maxGroupController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _nightsController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _bestSeasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Dropdowns ─────────────────────────────────────────────────────────────
  String _selectedDifficulty = 'Moderate';
  String _selectedCategory = 'Adventure';

  static const _difficulties = ['Easy', 'Moderate', 'Hard', 'Expert'];
  static const _categories = [
    'Adventure', 'Fort Trek', 'Spiritual', 'Beach', 'Road Trip',
    'Weekend Trip', 'Wildlife', 'Cultural',
  ];

  // ── Inclusions / Exclusions ───────────────────────────────────────────────
  final List<TextEditingController> _inclusionCtls = [TextEditingController()];
  final List<TextEditingController> _exclusionCtls = [TextEditingController()];

  // ── Itinerary ─────────────────────────────────────────────────────────────
  final List<_ItineraryDay> _itinerary = [_ItineraryDay(day: 1)];

  // ── Images ────────────────────────────────────────────────────────────────
  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    for (final c in [
      _titleController, _descController, _priceController,
      _maxGroupController, _daysController, _nightsController,
      _destinationController, _latController, _lngController,
      _bestSeasonController,
    ]) { c.dispose(); }
    for (final c in [..._inclusionCtls, ..._exclusionCtls]) { c.dispose(); }
    for (final d in _itinerary) { d.dispose(); }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images.take(5 - _pickedImages.length));
      });
    }
  }

  void _addActivity(int dayIndex) {
    setState(() => _itinerary[dayIndex].activities.add(TextEditingController()));
  }

  void _updateDurationFromDates() {
    if (_startDate != null && _endDate != null) {
      final difference = _endDate!.difference(_startDate!).inDays;
      if (difference >= 0) {
        final totalDays = difference + 1;
        setState(() {
          _daysController.text = totalDays.toString();
          _nightsController.text = difference.toString();

          // Sync itinerary steps count
          if (_itinerary.length < totalDays) {
            // Add missing days
            for (var i = _itinerary.length; i < totalDays; i++) {
              final date = _startDate!.add(Duration(days: i));
              _itinerary.add(_ItineraryDay(day: i + 1, date: date));
            }
          } else if (_itinerary.length > totalDays) {
            // Remove extra days
            for (var i = _itinerary.length - 1; i >= totalDays; i--) {
              _itinerary[i].dispose();
              _itinerary.removeAt(i);
            }
          }

          // Force update all dates and sequence numbers
          for (var i = 0; i < _itinerary.length; i++) {
            _itinerary[i].day = i + 1;
            _itinerary[i].date = _startDate!.add(Duration(days: i));
          }
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImages.isEmpty) {
      _showError('Please add at least one cover image.');
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final body = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'maxGroupSize': int.tryParse(_maxGroupController.text) ?? 0,
        'duration': {
          'days': int.tryParse(_daysController.text) ?? 1,
          'nights': int.tryParse(_nightsController.text) ?? 0,
        },
        'destination': {
          'name': _destinationController.text.trim(),
          'location': {
            'lat': double.tryParse(_latController.text) ?? 0.0,
            'lng': double.tryParse(_lngController.text) ?? 0.0,
          },
        },
        'difficulty': _selectedDifficulty,
        'category': _selectedCategory,
        if (_bestSeasonController.text.isNotEmpty)
          'bestSeason': _bestSeasonController.text.trim(),
        'inclusions': _inclusionCtls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'exclusions': _exclusionCtls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'itinerary': _itinerary.map((d) => d.toJson()).toList(),
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
      };

      final created = await _service.createPackage(
        body,
        imageFiles: _pickedImages.map((x) => File(x.path)).toList(),
      );

      if (!mounted) return;
      if (created) {
        // Refresh guide's package list
        context.read<TravelBloc>().add(TravelMyPackagesRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package created! It will go live after review. 🎉'),
            backgroundColor: successColorDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        _showError('Failed to create package. Please try again.');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: errorColorDark,
          behavior: SnackBarBehavior.floating),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        title: AppText.subHeading('Create Travel Package',
            fontWeight: FontWeight.w800),
        centerTitle: true,
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.ms),
          children: [
            // Images
            _buildSectionCard('Cover Images', Icons.photo_library_rounded, [
              _buildImagePicker(),
            ]),
            const SizedBox(height: 16),

            // Basic Info
            _buildSectionCard('Basic Information', Icons.info_outline_rounded, [
              _field('Package Title', 'e.g. Lohagad Monsoon Trek',
                  _titleController,
                  validator: _required),
              _field('Description',
                  'What makes this trip special? Include route, highlights...',
                  _descController,
                  maxLines: 4, validator: _required),
              Row(children: [
                Expanded(
                    child: _field('Price (₹/person)', '1499', _priceController,
                        inputType: TextInputType.number,
                        validator: _requiredNum)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Max Group Size', '20', _maxGroupController,
                        inputType: TextInputType.number,
                        validator: _requiredNum)),
              ]),
              Row(
                children: [
                  Expanded(
                    child: _datePicker('Start Date', _startDate, (d) {
                      setState(() => _startDate = d);
                      _updateDurationFromDates();
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _datePicker('End Date', _endDate, (d) {
                      setState(() => _endDate = d);
                      _updateDurationFromDates();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field('Days', '1', _daysController,
                        inputType: TextInputType.number,
                        readOnly: true,
                        validator: _requiredNum)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Nights', '0', _nightsController,
                        inputType: TextInputType.number, readOnly: true)),
              ]),
            ]),
            const SizedBox(height: 16),

            // Destination
            _buildSectionCard(
                'Destination', Icons.location_on_outlined, [
              _field('Place Name', 'e.g. Rajmachi, Pune',
                  _destinationController,
                  validator: _required),
              Row(children: [
                Expanded(
                    child: _field('Latitude', '18.5204', _latController,
                        inputType: const TextInputType.numberWithOptions(
                            decimal: true))),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Longitude', '73.8567', _lngController,
                        inputType: const TextInputType.numberWithOptions(
                            decimal: true))),
              ]),
              AppText.body(
                'Tip: Open Google Maps, long-press a location to copy coordinates.',
                color: appGrey,
                size: 11,
              ),
            ]),
            const SizedBox(height: 16),

            // Trip Details
            _buildSectionCard('Trip Details', Icons.tune_rounded, [
              Row(children: [
                Expanded(child: _buildDropdown('Difficulty', _difficulties,
                    _selectedDifficulty,
                    (v) => setState(() => _selectedDifficulty = v!))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Category', _categories,
                    _selectedCategory,
                    (v) => setState(() => _selectedCategory = v!))),
              ]),
              _field('Best Season (optional)',
                  'e.g. Monsoon, Winter', _bestSeasonController),
            ]),
            const SizedBox(height: 16),

            // Itinerary
            _buildSectionCard('Itinerary', Icons.route_rounded, [
              if (_startDate == null || _endDate == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: AppText.body(
                      'Please select Start and End dates first to generate the itinerary.',
                      color: appGrey,
                      align: TextAlign.center,
                    ),
                  ),
                )
              else
                ..._itinerary.asMap().entries.map((e) =>
                    _buildItineraryDayBlock(e.key, e.value)),
            ]),
            const SizedBox(height: 16),

            // Inclusions
            _buildSectionCard(
                'Inclusions & Exclusions', Icons.checklist_rounded, [
              AppText.subHeading('Included', color: successColorDark,
                  size: 13, fontWeight: FontWeight.w700),
              const SizedBox(height: 6),
              ..._inclusionCtls.asMap().entries.map((e) =>
                  _listItem(e.value, () => setState(() {
                        if (_inclusionCtls.length > 1) {
                          _inclusionCtls.removeAt(e.key);
                        }
                      }),
                      'e.g. Transport, Meals',
                      successColor)),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _inclusionCtls.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 16, color: successColorDark),
                label: const Text('Add Inclusion',
                    style: TextStyle(color: successColorDark)),
              ),
              const Divider(),
              AppText.subHeading('Excluded', color: errorColorDark,
                  size: 13, fontWeight: FontWeight.w700),
              const SizedBox(height: 6),
              ..._exclusionCtls.asMap().entries.map((e) =>
                  _listItem(e.value, () => setState(() {
                        if (_exclusionCtls.length > 1) {
                          _exclusionCtls.removeAt(e.key);
                        }
                      }),
                      'e.g. Personal expenses',
                      errorColor)),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _exclusionCtls.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 16, color: errorColorDark),
                label: const Text('Add Exclusion',
                    style: TextStyle(color: errorColorDark)),
              ),
            ]),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Preview & Publish',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────────

  Widget _buildSectionCard(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: shadowColorLight,
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: primaryBlue, size: 18),
            const SizedBox(width: 8),
            AppText.subHeading(title,
                fontWeight: FontWeight.w800, size: 15),
          ]),
          const SizedBox(height: 16),
          ...children.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 12), child: w)),
        ],
      ),
    );
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pickedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedImages.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == _pickedImages.length) {
                  return _addImageBtn();
                }
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(_pickedImages[i].path),
                          width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pickedImages.removeAt(i)),
                        child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 10,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: onboardingBlueVeryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: primaryBlue),
                  const SizedBox(height: 8),
                  AppText.body('Tap to upload cover images',
                      color: primaryBlue),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _addImageBtn() {
    if (_pickedImages.length >= 5) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: onboardingBlueVeryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: const Icon(Icons.add_rounded, color: primaryBlue, size: 30),
      ),
    );
  }

  // ── Field helpers ─────────────────────────────────────────────────────────

  Widget _field(
    String label,
    String hint,
    TextEditingController? controller, {
    TextInputType? inputType,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(label, size: 13, fontWeight: FontWeight.w700),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          style: GoogleFonts.montserrat(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.montserrat(color: appGreyLight, fontSize: 12),
            filled: true,
            fillColor: readOnly ? appGreyVeryLight.withOpacity(0.5) : appGreyVeryLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _datePicker(String label, DateTime? date, ValueChanged<DateTime?> onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(label, size: 13, fontWeight: FontWeight.w700),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final firstDate = DateTime.now();
            final lastDate = DateTime.now().add(const Duration(days: 365 * 5));
            final d = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: firstDate,
              lastDate: lastDate,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: primaryBlue,
                      onPrimary: Colors.white,
                      onSurface: appBlack,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (d != null) onPicked(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: appGreyVeryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: primaryBlue.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Choose date',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: date != null ? appBlack : appGreyLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(label, size: 13, fontWeight: FontWeight.w700),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: appGreyVeryLight,
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: Colors.black87),
              items: items
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style:
                              GoogleFonts.montserrat(fontSize: 13))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryDayBlock(int index, _ItineraryDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryBlue.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                  radius: 14,
                  backgroundColor: primaryBlue,
                  child: Text('${day.day}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: day.titleCtl,
                  style: GoogleFonts.montserrat(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Day ${day.day} title, e.g. Trek to summit',
                    hintStyle: GoogleFonts.montserrat(
                        color: appGreyLight, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      day.date != null ? DateFormat('dd MMM, yyyy').format(day.date!) : 'Pending',
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...day.activities.asMap().entries.map((e) => Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      style: GoogleFonts.montserrat(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Activity ${e.key + 1}...',
                        hintStyle: GoogleFonts.montserrat(
                            color: appGreyLight, fontSize: 11),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                ],
              )),
          TextButton.icon(
            onPressed: () => _addActivity(index),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Activity', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _listItem(TextEditingController ctl, VoidCallback onRemove,
      String hint, Color iconColor) {
    return Row(
      children: [
        Icon(Icons.label_outline, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: ctl,
            style: GoogleFonts.montserrat(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(
                  color: appGreyLight, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 16),
          onPressed: onRemove,
          color: errorColor,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // Validators
  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
  String? _requiredNum(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v) == null) return 'Must be a number';
    return null;
  }
}

// ── Data holder for one itinerary day ──────────────────────────────────────

class _ItineraryDay {
  int day;
  DateTime? date;
  final TextEditingController titleCtl = TextEditingController();
  final List<TextEditingController> activities = [TextEditingController()];

  _ItineraryDay({required this.day, this.date});

  void dispose() {
    titleCtl.dispose();
    for (final c in activities) { c.dispose(); }
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'title': titleCtl.text.trim(),
        'date': date?.toIso8601String(),
        'activities': activities
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      };
}
