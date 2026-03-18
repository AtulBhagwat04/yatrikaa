import 'dart:io';
import 'package:bhatkanti_app/Frontend/core/utils/error_handler.dart';
import 'package:bhatkanti_app/Frontend/core/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/services/events_service.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _organizerController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _contactController = TextEditingController();
  final _websiteController = TextEditingController();
  final _interestedCountController = TextEditingController(text: '0');

  final _picker = ImagePicker();
  List<XFile> _imageFiles = [];

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  String _selectedCategory = 'Cultural';
  String _entryType = 'Free';
  bool _isPopular = false;
  bool _isVerified = false;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  bool _isPickerActive = false;

  final List<String> _categories = [
    'Cultural',
    'Festival',
    'Adventure',
    'Spiritual',
    'Exhibition',
    'Workshop',
    'Concert',
    'Food Fair',
    'Other',
  ];

  final List<String> _entryTypes = ['Free', 'Charges'];

  final EventsService _eventsService = EventsService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _organizerController.dispose();
    _entryFeeController.dispose();
    _contactController.dispose();
    _websiteController.dispose();
    _interestedCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isPickerActive) return;

    if (_imageFiles.length >= 3) {
      CustomToast.warning(
        context,
        'Maximum 3 images allowed',
        title: "Hold on!",
      );
      return;
    }

    setState(() => _isPickerActive = true);
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          // Take only up to remaining slots
          int remainingSlots = 3 - _imageFiles.length;
          _imageFiles.addAll(pickedFiles.take(remainingSlots));
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: appWhite,
              onSurface: appBlack,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: appWhite,
              onSurface: appBlack,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
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
        List<String> addressParts = [];
        if (p.street != null && p.street!.isNotEmpty && p.street != p.name) {
          addressParts.add(p.street!);
        }
        if (p.locality != null && p.locality!.isNotEmpty) {
          addressParts.add(p.locality!);
        }
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          addressParts.add(p.administrativeArea!);
        }
        _addressController.text = addressParts.join(", ");
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final double lat = double.tryParse(_latController.text) ?? 0.0;
      final double lng = double.tryParse(_lngController.text) ?? 0.0;

      final success = await _eventsService.addEvent({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'startTime': _formatTimeOfDay(_startTime),
        'endTime': _formatTimeOfDay(_endTime),
        'venue': _venueController.text.trim(),
        'address': _addressController.text.trim(),
        'geometry': {
          'location': {'lat': lat, 'lng': lng},
        },
        'category': _selectedCategory,
        'organizer': _organizerController.text.trim(),
        'entryFee': _entryType == 'Free'
            ? 'Free'
            : _entryFeeController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'website': _websiteController.text.trim(),
        'interestedCount':
            int.tryParse(_interestedCountController.text.trim()) ?? 0,
        'isPopular': _isPopular,
        'isVerified': _isVerified,
      }, _imageFiles.map((x) => File(x.path)).toList());

      if (success && mounted) {
        CustomToast.success(context, 'Event added successfully!');
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
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            pinned: true,
            backgroundColor: onboardingBlueVeryLight,
            elevation: 0,
            title: AppText.heading(
              "Add New Event",
              size: 22,
              fontWeight: FontWeight.w900,
            ),
            centerTitle: true,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
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
                        title: "Event Images",
                        icon: Icons.image_rounded,
                        children: [_buildMultiImageUploader()],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: "Event Details",
                        icon: Icons.info_rounded,
                        children: [
                          _buildSleekField(
                            label: "Event Title",
                            controller: _titleController,
                            hint: "Enter official title...",
                            icon: Icons.title_rounded,
                          ),
                          _buildSleekDropdown(
                            label: "Category",
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _selectedCategory = v);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildSleekField(
                            label: "Description",
                            controller: _descriptionController,
                            hint: "What's happening in the event?",
                            icon: Icons.notes_rounded,
                            maxLines: null,
                            minLines: 1,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: "Schedule",
                        icon: Icons.calendar_month_rounded,
                        children: [
                          _buildInputLabel("Date"),
                          _buildDateSelector(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Start Time"),
                                    _buildTimeSelector(
                                      time: _startTime,
                                      onTap: () => _selectTime(true),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("End Time"),
                                    _buildTimeSelector(
                                      time: _endTime,
                                      onTap: () => _selectTime(false),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: "Location",
                        icon: Icons.location_on_rounded,
                        children: [
                          _buildSleekField(
                            label: "Venue Name",
                            controller: _venueController,
                            hint: "e.g. Balewadi Stadium",
                            icon: Icons.business_rounded,
                          ),
                          _buildSleekField(
                            label: "Address",
                            controller: _addressController,
                            hint: "Full landmark/area details...",
                            icon: Icons.map_rounded,
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
                        title: "Organizer & Fee",
                        icon: Icons.verified_user_rounded,
                        children: [
                          _buildSleekField(
                            label: "Organizer",
                            controller: _organizerController,
                            hint: "Individual or Organization",
                            icon: Icons.person_rounded,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildSleekDropdown(
                                  label: "Entry",
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
                                    label: "Fee Amount",
                                    controller: _entryFeeController,
                                    hint: "₹ 100",
                                    icon: Icons.payments_rounded,
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: "Contact Information",
                        icon: Icons.contact_page_rounded,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSleekField(
                                  label: "Contact No",
                                  controller: _contactController,
                                  hint: "9988XXXXXX",
                                  icon: Icons.phone_rounded,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSleekField(
                                  label: "Website",
                                  controller: _websiteController,
                                  hint: "https://... (Optional)",
                                  icon: Icons.language_rounded,
                                  isOptional: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: "Community & Visibility",
                        icon: Icons.people_rounded,
                        children: [
                          _buildSleekField(
                            label: "Initial Interested Count",
                            controller: _interestedCountController,
                            hint: "e.g. 50",
                            icon: Icons.favorite_rounded,
                            isNumber: true,
                          ),
                          _buildSleekSwitch(
                            label: "Mark as Popular Event",
                            value: _isPopular,
                            onChanged: (v) => setState(() => _isPopular = v),
                          ),
                          _buildSleekSwitch(
                            label: "Verified Organizer",
                            value: _isVerified,
                            onChanged: (v) => setState(() => _isVerified = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildActionBtn(
                        label: _isLoading ? "Adding Event..." : "Add Event",
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
        color: appWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
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
                color: appBlack,
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

  Widget _buildMultiImageUploader() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imageFiles.length + (_imageFiles.length < 3 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _imageFiles.length) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: onboardingBlueVeryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryBlue.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 24,
                      color: primaryBlue,
                    ),
                    const SizedBox(height: 4),
                    AppText.caption(
                      "Add Photo",
                      size: 10,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: FileImage(File(_imageFiles[index].path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 15,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: appBlack.withAlpha(138),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: appWhite),
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
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel(label),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: GoogleFonts.montserrat(
              color: appBlack.withAlpha(222),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(
                color: appGreyLight,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: primaryBlue, size: 16),
              filled: true,
              fillColor: onboardingBlueVeryLight.withAlpha(128),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            validator: (v) {
              if (isOptional) return null;
              return (v == null || v.trim().isEmpty) ? 'Field required' : null;
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
        color: appBlack.withAlpha(222),
      ),
    );
  }

  Widget _buildSleekDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String? label,
  }) {
    final dropdown = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: onboardingBlueVeryLight.withAlpha(128),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryBlue,
            size: 18,
          ),
          style: GoogleFonts.montserrat(
            color: appBlack.withAlpha(222),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
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

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: onboardingBlueVeryLight.withAlpha(128),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM, yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: appBlack,
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: primaryBlue,
            ),
          ],
        ),
      ),
    );
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
            const Icon(Icons.access_time_rounded, size: 16, color: primaryBlue),
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
          Switch(value: value, activeColor: primaryBlue, onChanged: onChanged),
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

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isSecondary
                ? BorderSide(color: primaryBlue.withOpacity(0.3))
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  AppText.button(
                    label,
                    size: 14,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ],
              ),
      ),
    );
  }
}
