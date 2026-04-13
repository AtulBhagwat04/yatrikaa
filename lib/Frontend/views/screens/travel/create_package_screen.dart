import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/services/packages_service.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:yatrikaa/Frontend/views/widgets/modern/modern_location_field.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:yatrikaa/Frontend/core/utils/logger_service.dart';

/// Screen for guides / admins to create a new travel package.
/// All data is submitted to the backend via [PackagesService].
class CreatePackageScreen extends StatefulWidget {
  final TravelPackageModel? package;
  const CreatePackageScreen({super.key, this.package});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Basic Info ────────────────────────────────────────────────────────────
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _maxGroupController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _nightsController = TextEditingController();
  final TextEditingController _bestSeasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isComingSoon = false;

  // ── Dropdowns ─────────────────────────────────────────────────────────────
  String _selectedDifficulty = 'Moderate';
  String _selectedCategory = 'Adventure';

  static const _difficulties = ['Easy', 'Moderate', 'Hard', 'Expert'];
  static const _categories = [
    'Adventure',
    'Fort Trek',
    'Spiritual',
    'Beach',
    'Road Trip',
    'Weekend Trip',
    'Wildlife',
    'Cultural',
  ];

  // ── Inclusions / Exclusions ───────────────────────────────────────────────
  final List<TextEditingController> _inclusionCtls = [TextEditingController()];
  final List<FocusNode> _inclusionNodes = [FocusNode()];
  final List<TextEditingController> _exclusionCtls = [TextEditingController()];
  final List<FocusNode> _exclusionNodes = [FocusNode()];

  // ── Itinerary ─────────────────────────────────────────────────────────────
  final List<_ItineraryDay> _itinerary = [_ItineraryDay(day: 1)];

  // ── Images ────────────────────────────────────────────────────────────────
  final List<XFile> _pickedImages = [];
  List<String> _existingImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      final pkg = widget.package!;
      _titleController.text = pkg.title;
      _descController.text = pkg.description;
      _priceController.text = pkg.price.toString();
      _maxGroupController.text = pkg.maxGroupSize.toString();
      _daysController.text = pkg.days.toString();
      _nightsController.text = pkg.nights.toString();
      _bestSeasonController.text = pkg.bestSeason ?? '';
      _startDate = pkg.startDate;
      _endDate = pkg.endDate;
      _selectedDifficulty = pkg.difficulty;
      _selectedCategory = pkg.category;
      _existingImages = List.from(pkg.images);
      _isComingSoon = pkg.isComingSoon;

      // Inclusions
      _inclusionCtls.clear();
      _inclusionNodes.clear();
      if (pkg.inclusions.isEmpty) {
        _inclusionCtls.add(TextEditingController());
        _inclusionNodes.add(FocusNode());
      } else {
        for (final item in pkg.inclusions) {
          _inclusionCtls.add(TextEditingController(text: item));
          _inclusionNodes.add(FocusNode());
        }
      }

      // Exclusions
      _exclusionCtls.clear();
      _exclusionNodes.clear();
      if (pkg.exclusions.isEmpty) {
        _exclusionCtls.add(TextEditingController());
        _exclusionNodes.add(FocusNode());
      } else {
        for (final item in pkg.exclusions) {
          _exclusionCtls.add(TextEditingController(text: item));
          _exclusionNodes.add(FocusNode());
        }
      }

      // Itinerary
      _itinerary.clear();
      if (pkg.itinerary.isEmpty) {
        _itinerary.add(_ItineraryDay(day: 1));
        _itinerary.first.titleCtl.text = "Day 1";
      } else {
        for (final step in pkg.itinerary) {
          final day = _ItineraryDay(day: step.day, date: step.date);
          day.titleCtl.text = step.title;

          // Places
          day.places.clear();
          day.placeNodes.clear();
          for (final place in step.places) {
            day.places.add(TextEditingController(text: place));
            day.placeNodes.add(FocusNode());
          }
          if (day.places.isEmpty) {
            day.places.add(TextEditingController());
            day.placeNodes.add(FocusNode());
          }

          // Hotels
          day.hotels.clear();
          day.hotelNodes.clear();
          for (final hotel in step.hotelName) {
            day.hotels.add(TextEditingController(text: hotel));
            day.hotelNodes.add(FocusNode());
          }
          if (day.hotels.isEmpty) {
            day.hotels.add(TextEditingController());
            day.hotelNodes.add(FocusNode());
          }

          // Stays
          day.stays.clear();
          day.stayNodes.clear();
          for (final stay in step.stayLocation) {
            day.stays.add(TextEditingController(text: stay));
            day.stayNodes.add(FocusNode());
          }
          if (day.stays.isEmpty) {
            day.stays.add(TextEditingController());
            day.stayNodes.add(FocusNode());
          }

          day.activities.clear();
          day.activityNodes.clear();
          for (final activity in step.activities) {
            day.activities.add(TextEditingController(text: activity));
            day.activityNodes.add(FocusNode());
          }
          if (day.activities.isEmpty) {
            day.activities.add(TextEditingController());
            day.activityNodes.add(FocusNode());
          }
          _itinerary.add(day);
        }
      }
    } else {
      _itinerary.first.titleCtl.text = "Day 1";
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleController,
      _descController,
      _priceController,
      _maxGroupController,
      _daysController,
      _nightsController,
      _bestSeasonController,
    ]) {
      c.dispose();
    }
    for (final c in [..._inclusionCtls, ..._exclusionCtls]) {
      c.dispose();
    }
    for (final n in [..._inclusionNodes, ..._exclusionNodes]) {
      n.dispose();
    }
    for (final d in _itinerary) {
      d.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    if (_existingImages.length + _pickedImages.length >= 10) {
      _showError('Maximum 10 images allowed');
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
      if (!mounted) return;
      if (images.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(
            images.take(10 - (_existingImages.length + _pickedImages.length)),
          );
        });
      }
    } catch (e) {
      Log.e("Error picking images: $e");
    }
  }

  void _addActivity(int dayIndex) {
    setState(() {
      _itinerary[dayIndex].activities.add(TextEditingController());
      _itinerary[dayIndex].activityNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itinerary[dayIndex].activityNodes.last.requestFocus();
    });
  }

  void _addPlace(int dayIndex) {
    setState(() {
      _itinerary[dayIndex].places.add(TextEditingController());
      _itinerary[dayIndex].placeNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itinerary[dayIndex].placeNodes.last.requestFocus();
    });
  }

  void _addHotel(int dayIndex) {
    setState(() {
      _itinerary[dayIndex].hotels.add(TextEditingController());
      _itinerary[dayIndex].hotelNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itinerary[dayIndex].hotelNodes.last.requestFocus();
    });
  }

  void _addStay(int dayIndex) {
    setState(() {
      _itinerary[dayIndex].stays.add(TextEditingController());
      _itinerary[dayIndex].stayNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itinerary[dayIndex].stayNodes.last.requestFocus();
    });
  }

  void _addInclusion() {
    setState(() {
      _inclusionCtls.add(TextEditingController());
      _inclusionNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inclusionNodes.last.requestFocus();
    });
  }

  void _addExclusion() {
    setState(() {
      _exclusionCtls.add(TextEditingController());
      _exclusionNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _exclusionNodes.last.requestFocus();
    });
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
              final dayNum = i + 1;
              final date = _startDate!.add(Duration(days: i));
              final newDay = _ItineraryDay(day: dayNum, date: date);
              newDay.titleCtl.text = "Day $dayNum"; // Auto-populate title
              _itinerary.add(newDay);
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
            final dayNum = i + 1;
            final oldDayNum = _itinerary[i].day;
            _itinerary[i].day = dayNum;
            _itinerary[i].date = _startDate!.add(Duration(days: i));

            // If the title is empty or was the previous automatic Day name, update it
            if (_itinerary[i].titleCtl.text.isEmpty ||
                _itinerary[i].titleCtl.text == "Day $oldDayNum") {
              _itinerary[i].titleCtl.text = "Day $dayNum";
            }
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
    if (_pickedImages.isEmpty &&
        _existingImages.isEmpty &&
        widget.package == null) {
      _showError('Please add at least one image.');
      return;
    }

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
        'name': 'Multiple Places',
        'location': {'lat': 0.0, 'lng': 0.0},
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
      'isComingSoon': _isComingSoon,
    };

    if (widget.package != null) {
      context.read<TravelBloc>().add(
        TravelUpdatePackageRequested(
          packageId: widget.package!.id,
          body: {...body, 'images': _existingImages},
          imageFiles: _pickedImages.map((x) => File(x.path)).toList(),
        ),
      );
    } else {
      context.read<TravelBloc>().add(
        TravelCreatePackageRequested(
          body: body,
          imageFiles: _pickedImages.map((x) => File(x.path)).toList(),
        ),
      );
    }
  }

  void _showError(String msg) {
    CustomToast.error(context, msg);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<TravelBloc, TravelState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == BookingActionStatus.success) {
          CustomToast.success(context, state.actionSuccessMessage ?? 'Success!');
          context.read<TravelBloc>().add(TravelStatusReset());
          Navigator.pop(context);
        } else if (state.actionStatus == BookingActionStatus.failure) {
          _showError(state.actionError ?? 'Something went wrong');
          context.read<TravelBloc>().add(TravelStatusReset());
        }
      },
      child: Scaffold(
        backgroundColor: onboardingBlueVeryLight,
        appBar: AppBar(
          title: AppText.subHeading(
            widget.package != null ? 'Edit Package' : 'Create Travel Package',
            fontWeight: FontWeight.w800,
          ),
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
                _field(
                  'Package Title',
                  'e.g. Lohagad Monsoon Trek',
                  _titleController,
                  validator: _required,
                ),
                _field(
                  'Description',
                  'What makes this trip special? Include route, highlights...',
                  _descController,
                  maxLines: 4,
                  validator: _required,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Price (₹/person)',
                        '1499',
                        _priceController,
                        inputType: TextInputType.number,
                        validator: _requiredNum,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Max Group Size',
                        '20',
                        _maxGroupController,
                        inputType: TextInputType.number,
                        validator: _requiredNum,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _datePicker('Start Date', _startDate, (d) {
                        setState(() {
                          _startDate = d;
                          // Reset end date if it's now before start date
                          if (_endDate != null &&
                              _startDate != null &&
                              _endDate!.isBefore(_startDate!)) {
                            _endDate = null;
                          }
                        });
                        _updateDurationFromDates();
                      }, firstDate: DateTime.now()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _datePicker('End Date', _endDate, (d) {
                        setState(() => _endDate = d);
                        _updateDurationFromDates();
                      }, firstDate: _startDate ?? DateTime.now()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Days',
                        '1',
                        _daysController,
                        inputType: TextInputType.number,
                        readOnly: true,
                        validator: _requiredNum,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Nights',
                        '0',
                        _nightsController,
                        inputType: TextInputType.number,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: AppText.body(
                    'Mark as Coming Soon',
                    fontWeight: FontWeight.w700,
                    size: 14,
                  ),
                  subtitle: AppText.body(
                    'Users can see the package but cannot book it yet. Day-by-day itinerary will be hidden.',
                    size: 11,
                    color: appGrey,
                  ),
                  value: _isComingSoon,
                  activeThumbColor: primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isComingSoon = val),
                ),
              ]),
              const SizedBox(height: 16),

              // Destination section removed as requested - moved to Itinerary day by day planning.
              const SizedBox(height: 16),

              // Trip Details
              _buildSectionCard('Trip Details', Icons.tune_rounded, [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Difficulty',
                        _difficulties,
                        _selectedDifficulty,
                        (v) => setState(() => _selectedDifficulty = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        'Category',
                        _categories,
                        _selectedCategory,
                        (v) => setState(() => _selectedCategory = v!),
                      ),
                    ),
                  ],
                ),
                _field(
                  'Best Season (optional)',
                  'e.g. Monsoon, Winter',
                  _bestSeasonController,
                ),
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
                  ..._itinerary.asMap().entries.map(
                    (e) => _buildItineraryDayBlock(e.key, e.value),
                  ),
              ]),
              const SizedBox(height: 16),

              // Inclusions
              _buildSectionCard(
                'Inclusions & Exclusions',
                Icons.checklist_rounded,
                [
                  AppText.subHeading(
                    'Included',
                    color: successColorDark,
                    size: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 6),
                  ..._inclusionCtls.asMap().entries.map(
                    (e) => _listItem(
                      e.value,
                      _inclusionNodes[e.key],
                      () => setState(() {
                        if (_inclusionCtls.length > 1) {
                          _inclusionCtls.removeAt(e.key);
                          _inclusionNodes[e.key].dispose();
                          _inclusionNodes.removeAt(e.key);
                        }
                      }),
                      'e.g. Transport, Meals',
                      successColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addInclusion,
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: successColorDark,
                    ),
                    label: const Text(
                      'Add Inclusion',
                      style: TextStyle(color: successColorDark),
                    ),
                  ),
                  const Divider(),
                  AppText.subHeading(
                    'Excluded',
                    color: errorColorDark,
                    size: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 6),
                  ..._exclusionCtls.asMap().entries.map(
                    (e) => _listItem(
                      e.value,
                      _exclusionNodes[e.key],
                      () => setState(() {
                        if (_exclusionCtls.length > 1) {
                          _exclusionCtls.removeAt(e.key);
                          _exclusionNodes[e.key].dispose();
                          _exclusionNodes.removeAt(e.key);
                        }
                      }),
                      'e.g. Personal expenses',
                      errorColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addExclusion,
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: errorColorDark,
                    ),
                    label: const Text(
                      'Add Exclusion',
                      style: TextStyle(color: errorColorDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit
              BlocBuilder<TravelBloc, TravelState>(
                builder: (context, state) {
                  final isSubmitting =
                      state.actionStatus == BookingActionStatus.loading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.package != null
                                  ? 'Update Package'
                                  : 'Preview & Publish',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────────

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryBlue, size: 18),
              const SizedBox(width: 8),
              AppText.subHeading(title, fontWeight: FontWeight.w800, size: 15),
            ],
          ),
          const SizedBox(height: 16),
          ...children.map(
            (w) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
          ),
        ],
      ),
    );
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pickedImages.isNotEmpty || _existingImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length + _pickedImages.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == _existingImages.length + _pickedImages.length) {
                  return _addImageBtn();
                }

                // Show existing images from network
                if (i < _existingImages.length) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _existingImages[i],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _existingImages.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.redAccent,
                            child: Icon(
                              Icons.close,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Show newly picked local images
                final localIdx = i - _existingImages.length;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_pickedImages[localIdx].path),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pickedImages.removeAt(localIdx)),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
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
                border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: primaryBlue,
                  ),
                  const SizedBox(height: 8),
                  AppText.body(
                    widget.package != null
                        ? 'Add new cover images (optional)'
                        : 'Tap to upload cover images',
                    color: primaryBlue,
                  ),
                  if (widget.package != null) ...[
                    const SizedBox(height: 4),
                    AppText.caption(
                      'Leave empty to keep existing images',
                      color: appGrey,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _addImageBtn() {
    if (_pickedImages.length >= 10) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: onboardingBlueVeryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
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
    TextInputAction textInputAction = TextInputAction.next,
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
          textInputAction: textInputAction,
          validator: validator,
          style: GoogleFonts.montserrat(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
              color: appGreyLight,
              fontSize: 12,
            ),
            filled: true,
            fillColor: readOnly
                ? appGreyVeryLight.withValues(alpha: 0.5)
                : appGreyVeryLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onPicked, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(label, size: 13, fontWeight: FontWeight.w700),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final fDate = firstDate ?? DateTime.now();
            final lDate =
                lastDate ?? DateTime.now().add(const Duration(days: 365 * 5));
            final d = await showDatePicker(
              context: context,
              initialDate: (date != null && !date.isBefore(fDate))
                  ? date
                  : fDate,
              firstDate: fDate,
              lastDate: lDate,
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
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: primaryBlue.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Choose date',
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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(label, size: 13, fontWeight: FontWeight.w700),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: appGreyVeryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.black87,
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: GoogleFonts.montserrat(fontSize: 13),
                      ),
                    ),
                  )
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primaryBlue,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: day.titleCtl,
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Day ${day.day} title, e.g. Trek to summit',
                    hintStyle: GoogleFonts.montserrat(
                      color: appGreyLight,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      day.date != null
                          ? DateFormat('dd MMM, yyyy').format(day.date!)
                          : 'Pending',
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
          const SizedBox(height: 12),
          // 📍 PLACES TO VISIT
          _itineraryHeader(Icons.location_on_rounded, 'Places to visit'),
          ...day.places.asMap().entries.map(
            (e) => _itineraryListField(
              e.value,
              day.placeNodes[e.key],
              'Place ${e.key + 1}',
              Icons.location_on_rounded,
              () => setState(() {
                if (day.places.length > 1) {
                  day.places.removeAt(e.key);
                  day.placeNodes[e.key].dispose();
                  day.placeNodes.removeAt(e.key);
                }
              }),
            ),
          ),
          _itineraryAddBtn('Add Place', () => _addPlace(index)),

          const SizedBox(height: 10),
          // 🏨 HOTELS (Breakfast/Lunch/Dinner/Wait)
          _itineraryHeader(Icons.hotel_rounded, 'Hotels / Dining'),
          ...day.hotels.asMap().entries.map(
            (e) => _itineraryListField(
              e.value,
              day.hotelNodes[e.key],
              'Hotel ${e.key + 1}',
              Icons.hotel_rounded,
              () => setState(() {
                if (day.hotels.length > 1) {
                  day.hotels.removeAt(e.key);
                  day.hotelNodes[e.key].dispose();
                  day.hotelNodes.removeAt(e.key);
                }
              }),
            ),
          ),
          _itineraryAddBtn('Add Hotel/Dining', () => _addHotel(index)),

          const SizedBox(height: 10),
          // 🛌 STAY LOCATIONS
          _itineraryHeader(Icons.map_rounded, 'Stay Locations'),
          ...day.stays.asMap().entries.map(
            (e) => _itineraryListField(
              e.value,
              day.stayNodes[e.key],
              'Location ${e.key + 1}',
              Icons.map_rounded,
              () => setState(() {
                if (day.stays.length > 1) {
                  day.stays.removeAt(e.key);
                  day.stayNodes[e.key].dispose();
                  day.stayNodes.removeAt(e.key);
                }
              }),
            ),
          ),
          _itineraryAddBtn('Add Stay Location', () => _addStay(index)),

          const SizedBox(height: 12),
          _itineraryHeader(Icons.task_alt_rounded, 'Activities'),
          ...day.activities.asMap().entries.map(
            (e) => _itineraryListField(
              e.value,
              day.activityNodes[e.key],
              'Activity ${e.key + 1}',
              Icons.task_alt_rounded,
              () => setState(() {
                if (day.activities.length > 1) {
                  day.activities.removeAt(e.key);
                  day.activityNodes[e.key].dispose();
                  day.activityNodes.removeAt(e.key);
                }
              }),
            ),
          ),
          _itineraryAddBtn('Add Activity', () => _addActivity(index)),
        ],
      ),
    );
  }

  Widget _itineraryHeader(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 12, color: primaryBlue),
          const SizedBox(width: 4),
          AppText.body(label, size: 11, fontWeight: FontWeight.w800),
        ],
      ),
    );
  }

  Widget _itineraryAddBtn(String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: primaryBlue,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _itineraryListField(
    TextEditingController ctl,
    FocusNode node,
    String hint,
    IconData icon,
    VoidCallback onRemove,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: ModernLocationField(
              controller: ctl,
              hint: hint,
              icon: icon,
              showLabel: false,
              isDense: true,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 14),
            onPressed: onRemove,
            color: errorColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

Widget _listItem(
  TextEditingController ctl,
  FocusNode node,
  VoidCallback onRemove,
  String hint,
  Color iconColor,
) {
  return Row(
    children: [
      Icon(Icons.label_outline, size: 16, color: iconColor),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: ctl,
          focusNode: node,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.montserrat(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
              color: appGreyLight,
              fontSize: 12,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
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

  final List<TextEditingController> places = [TextEditingController()];
  final List<FocusNode> placeNodes = [FocusNode()];

  final List<TextEditingController> hotels = [TextEditingController()];
  final List<FocusNode> hotelNodes = [FocusNode()];

  final List<TextEditingController> stays = [TextEditingController()];
  final List<FocusNode> stayNodes = [FocusNode()];

  final List<TextEditingController> activities = [TextEditingController()];
  final List<FocusNode> activityNodes = [FocusNode()];

  _ItineraryDay({required this.day, this.date});

  void dispose() {
    titleCtl.dispose();
    for (final c in [...places, ...hotels, ...stays, ...activities]) {
      c.dispose();
    }
    for (final n in [
      ...placeNodes,
      ...hotelNodes,
      ...stayNodes,
      ...activityNodes,
    ]) {
      n.dispose();
    }
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'title': titleCtl.text.trim(),
    'date': date?.toIso8601String(),
    'places': places
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList(),
    'hotelName': hotels
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList(),
    'stayLocation': stays
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList(),
    'activities': activities
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList(),
  };
}
