import 'dart:io';
import 'package:bhatkanti_app/Frontend/core/widgets/custom_toast.dart';
import 'package:bhatkanti_app/Frontend/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/services/places_service.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _suitableForController =
      TextEditingController(); // Hidden but used in submit
  final _websiteController =
      TextEditingController(); // Hidden but used in submit
  final _customFacilityController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final _picker = ImagePicker();
  List<XFile> _imageFiles = [];

  String _selectedCategory = AppStrings.catForts;
  String _selectedDifficulty = AppStrings.pdEasy;
  String _entryType = 'Free';
  bool _parkingAvailable = true;
  bool _photographyAllowed = true;

  final List<String> _categories = [
    AppStrings.catForts,
    AppStrings.catBeaches,
    AppStrings.catTemples,
    AppStrings.catHillStations,
    AppStrings.catCaves,
    AppStrings.catWaterfalls,
    AppStrings.catTrekking,
    AppStrings.catWildlife,
    AppStrings.catSpiritual,
    'Other',
  ];

  final List<String> _difficulties = [
    AppStrings.pdEasy,
    'Moderate',
    'Hard',
    'Challenging',
  ];

  final List<String> _entryTypes = ['Free', 'Charges'];

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String _fromMonth = 'Jan';
  String _toMonth = 'Dec';

  final List<String> _facilityOptions = [
    'All Basic Facilities',
    'Drinking Water',
    'Restrooms',
    'Food Stalls',
    'Guides/Info Desk',
    'First Aid',
    'Seating Area',
    'Dustbins',
    'Parking Area',
    'Photography Point',
    'Locker Room',
    'Other',
  ];
  List<String> _selectedFacilities = ['All Basic Facilities'];
  String? _currentFacilityOption;

  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 17, minute: 0);

  bool _isLoading = false;
  bool _isLocationLoading = false;
  bool _isPickerActive = false;
  final PlacesService _placesService = PlacesService();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _entryFeeController.dispose();
    _suitableForController.dispose();
    _websiteController.dispose();
    _customFacilityController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickerActive) return;

    setState(() => _isPickerActive = true);
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
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

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      setState(() => _isLocationLoading = true);
      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks[0];

        // Build a more readable address without "initials" or redundant name codes
        List<String> addressParts = [];

        // Use street if available and not just a code
        if (p.street != null && p.street!.isNotEmpty && p.street != p.name) {
          addressParts.add(p.street!);
        } else if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          addressParts.add(p.subLocality!);
        }

        if (p.locality != null &&
            p.locality!.isNotEmpty &&
            !addressParts.contains(p.locality)) {
          addressParts.add(p.locality!);
        }

        if (p.administrativeArea != null &&
            p.administrativeArea!.isNotEmpty &&
            !addressParts.contains(p.administrativeArea)) {
          addressParts.add(p.administrativeArea!);
        }

        if (p.postalCode != null && p.postalCode!.isNotEmpty) {
          addressParts.add(p.postalCode!);
        }

        _addressController.text = addressParts.join(", ");
        _cityController.text = p.locality ?? p.subLocality ?? "";
        _stateController.text = p.administrativeArea ?? "";
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  Future<void> _selectTime(bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) return;

    setState(() => _isLoading = true);
    try {
      final String safeName = _nameController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final String autoPlaceId =
          "${safeName}_${DateTime.now().millisecondsSinceEpoch}";

      final String entryFeeValue = _entryType == 'Free'
          ? 'Free'
          : _entryFeeController.text.trim();

      final double lat = double.tryParse(_latController.text) ?? 0.0;
      final double lng = double.tryParse(_lngController.text) ?? 0.0;

      final success = await _placesService.addPlace({
        'place_id': autoPlaceId,
        'name': _nameController.text.trim(),
        'formatted_address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'geometry': {
          'location': {'lat': lat, 'lng': lng},
        },
        'editorial_summary': {'overview': _descriptionController.text.trim()},
        'opening_hours': {
          'weekday_text': [
            "${_formatTimeOfDay(_fromTime)} - ${_formatTimeOfDay(_toTime)}",
          ],
          'open_now': true,
        },
        'entry_fee': entryFeeValue,
        'best_time': "$_fromMonth - $_toMonth",
        'difficulty': _selectedDifficulty,
        'parking_available': _parkingAvailable,
        'suitable_for': _suitableForController.text.trim(),
        'photography_allowed': _photographyAllowed,
        'facilities': _selectedFacilities,
        'website': _websiteController.text.trim(),
        'rating': 4.5,
        'user_ratings_total': 0,
        'types': [
          (_selectedCategory == 'Other'
                  ? _customCategoryController.text.trim()
                  : _selectedCategory)
              .toLowerCase(),
        ],
      }, imageFiles: _imageFiles);

      if (success && mounted) {
        CustomToast.success(context, AppStrings.apSuccessMsg);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- HEADER ---
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            pinned: true,
            backgroundColor: onboardingBlueVeryLight,
            elevation: 0,
            scrolledUnderElevation: 2,
            surfaceTintColor: Colors.white,
            title: AppText.heading(
              AppStrings.apTitle,
              size: 22,
              fontWeight: FontWeight.w900,
            ),
            centerTitle: true,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // --- FORM CONTENT ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionCard(
                        title: "Place Image",
                        icon: Icons.image,
                        children: [_buildImageUploader()],
                      ),
                      const SizedBox(height: 12),

                      _buildSectionCard(
                        title: "Details",
                        icon: Icons.info,
                        children: [
                          _buildSleekField(
                            label: "Place Name",
                            controller: _nameController,
                            hint: "Enter official name...",
                            icon: Icons.place_rounded,
                          ),
                          _buildInputLabel("Category"),
                          _buildSleekDropdown(
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedCategory = v;
                                  if (v != 'Other') {
                                    _customCategoryController.clear();
                                  }
                                });
                              }
                            },
                          ),
                          if (_selectedCategory == 'Other') ...[
                            const SizedBox(height: 12),
                            _buildSleekField(
                              label: "Specify Category",
                              controller: _customCategoryController,
                              hint: "e.g. Museum, Park...",
                              icon: Icons.category_rounded,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildSleekField(
                            label: "Description",
                            controller: _descriptionController,
                            hint: "Tell something about this place...",
                            icon: Icons.notes_rounded,
                            maxLines: null,
                            minLines: 1,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildSectionCard(
                        title: "Geography",
                        icon: Icons.location_on_rounded,
                        children: [
                          _buildSleekField(
                            label: "Location Address",
                            controller: _addressController,
                            hint: "Full landmark/area details...",
                            icon: Icons.map_rounded,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSleekField(
                                  label: "City",
                                  controller: _cityController,
                                  hint: "City",
                                  icon: Icons.location_city_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSleekField(
                                  label: "State",
                                  controller: _stateController,
                                  hint: "State",
                                  icon: Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSleekField(
                                  label: "Lat",
                                  controller: _latController,
                                  hint: "18.XXXX",
                                  icon: Icons.gps_fixed_rounded,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSleekField(
                                  label: "Lng",
                                  controller: _lngController,
                                  hint: "72.XXXX",
                                  icon: Icons.gps_fixed_rounded,
                                  isNumber: true,
                                ),
                              ),
                            ],
                          ),
                          _buildActionBtn(
                            label: _isLocationLoading
                                ? "Getting Location..."
                                : "Use Current Location",
                            icon: Icons.my_location_rounded,
                            onPressed: _isLoading || _isLocationLoading
                                ? null
                                : _getCurrentLocation,
                            isSecondary: true,
                            isLoading: _isLocationLoading,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildSectionCard(
                        title: "Travel Dynamics",
                        icon: Icons.auto_awesome_rounded,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildSleekDropdown(
                                  label: "Entry Fee",
                                  value: _entryType,
                                  items: _entryTypes,
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _entryType = v);
                                  },
                                ),
                              ),
                              if (_entryType == 'Charges') ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSleekField(
                                    label: "Amount",
                                    controller: _entryFeeController,
                                    hint: "₹ 50",
                                    icon: Icons.payments_rounded,
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInputLabel("Best Season"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSleekDropdown(
                                  value: _fromMonth,
                                  items: _months,
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _fromMonth = v);
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: AppText.small("to", color: Colors.grey),
                              ),
                              Expanded(
                                child: _buildSleekDropdown(
                                  value: _toMonth,
                                  items: _months,
                                  onChanged: (v) {
                                    if (v != null) setState(() => _toMonth = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInputLabel("Visiting Hours"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeSelector(
                                  time: _fromTime,
                                  onTap: () => _selectTime(true),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: AppText.small("to", color: Colors.grey),
                              ),
                              Expanded(
                                child: _buildTimeSelector(
                                  time: _toTime,
                                  onTap: () => _selectTime(false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInputLabel("Difficulty Level"),
                          _buildSleekDropdown(
                            value: _selectedDifficulty,
                            items: _difficulties,
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _selectedDifficulty = v);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildSectionCard(
                        title: "Settings & Perks",
                        icon: Icons.verified_user_rounded,
                        children: [
                          _buildInputLabel("Facilities"),
                          if (_selectedFacilities.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _selectedFacilities
                                    .map(
                                      (f) => Chip(
                                        label: AppText.small(
                                          f,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        backgroundColor: primaryBlue,
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedFacilities.remove(f);
                                            if (_selectedFacilities.isEmpty) {
                                              _selectedFacilities.add(
                                                'All Basic Facilities',
                                              );
                                            }
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSleekDropdown(
                                      value: _currentFacilityOption,
                                      items: _facilityOptions,
                                      hint: "Choose Available Facilities",
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() {
                                            _currentFacilityOption = v;
                                            if (v == 'All Basic Facilities') {
                                              _selectedFacilities.clear();
                                              _selectedFacilities.add(v);
                                            } else if (v != 'Other' &&
                                                !_selectedFacilities.contains(
                                                  v,
                                                )) {
                                              if (_selectedFacilities.contains(
                                                'All Basic Facilities',
                                              )) {
                                                _selectedFacilities.remove(
                                                  'All Basic Facilities',
                                                );
                                              }
                                              _selectedFacilities.add(v);
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (_currentFacilityOption == 'Other') ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 4,
                                  child: TextFormField(
                                    controller: _customFacilityController,
                                    style: GoogleFonts.montserrat(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: "Add facility",
                                      fillColor: onboardingBlueVeryLight
                                          .withOpacity(0.5),
                                      filled: true,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.all(12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onFieldSubmitted: (v) {
                                      final text = v.trim();
                                      if (text.isNotEmpty) {
                                        setState(() {
                                          if (!_selectedFacilities.contains(
                                            text,
                                          )) {
                                            if (_selectedFacilities.contains(
                                              'All Basic Facilities',
                                            )) {
                                              _selectedFacilities.remove(
                                                'All Basic Facilities',
                                              );
                                            }
                                            _selectedFacilities.add(text);
                                          }
                                          _customFacilityController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSleekSwitch(
                            label: "Parking Available",
                            value: _parkingAvailable,
                            onChanged: (v) =>
                                setState(() => _parkingAvailable = v),
                          ),
                          const SizedBox(height: 8),
                          _buildSleekSwitch(
                            label: "Photography Allowed",
                            value: _photographyAllowed,
                            onChanged: (v) =>
                                setState(() => _photographyAllowed = v),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _buildActionBtn(
                        label: _isLoading ? "Adding New Place" : "Add Place",
                        onPressed: _isLoading ? null : _submit,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryBlue),
              const SizedBox(width: 10),
              AppText.subHeading(
                title.toUpperCase(),
                size: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImageUploader() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _imageFiles.isEmpty
          ? InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 40,
                    color: primaryBlue.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  AppText.small(
                    "Click to select multiple images",
                    color: primaryBlue,
                  ),
                ],
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: _imageFiles.length + 1,
              itemBuilder: (context, index) {
                if (index == _imageFiles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          color: primaryBlue.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }
                return Stack(
                  children: [
                    Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(File(_imageFiles[index].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSleekField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLines = 1,
    int? minLines,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: AppText.caption(
              label,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: primaryBlue, size: 16),
              filled: true,
              fillColor: onboardingBlueVeryLight.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Field required';
              if (isNumber && double.tryParse(v.trim()) == null)
                return 'Invalid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: AppText.caption(
        label,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSleekDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
    String? label,
  }) {
    final dropdown = Container(
      height: 48, // Improved height consistency
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          hint: hint != null
              ? Text(
                  hint,
                  style: GoogleFonts.montserrat(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                )
              : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryBlue,
            size: 18,
          ),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          menuMaxHeight: 300,
        ),
      ),
    );

    if (label != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildInputLabel(label), dropdown],
        ),
      );
    }
    return dropdown;
  }

  Widget _buildTimeSelector({
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: onboardingBlueVeryLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTimeOfDay(time),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleekSwitch({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(
            label,
            size: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          Switch(
            value: value,
            activeColor: primaryBlue,
            activeTrackColor: primaryBlue.withOpacity(0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    bool isSecondary = false,
    bool isLoading = false,
  }) {
    final baseColor = isSecondary ? primaryBlue.withOpacity(0.08) : primaryBlue;
    final fgColor = isSecondary ? primaryBlue : Colors.white;

    final style = ElevatedButton.styleFrom(
      backgroundColor: baseColor,
      foregroundColor: fgColor,
      disabledBackgroundColor: baseColor,
      disabledForegroundColor: fgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSecondary
            ? BorderSide(color: primaryBlue.withOpacity(0.3))
            : BorderSide.none,
      ),
    );

    final labelWidget = AppText.button(
      label,
      size: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: isSecondary ? primaryBlue : Colors.white,
    );

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSecondary
            ? null
            : [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: (icon == null && !isLoading)
          ? ElevatedButton(
              key: const ValueKey("standard_action_btn"),
              onPressed: onPressed,
              style: style,
              child: labelWidget,
            )
          : ElevatedButton.icon(
              key: const ValueKey("icon_action_btn"),
              onPressed: onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isSecondary ? primaryBlue : Colors.white,
                      ),
                    )
                  : (icon != null
                        ? Icon(icon, size: 18)
                        : const SizedBox.shrink()),
              label: labelWidget,
              style: style,
            ),
    );
  }
}
