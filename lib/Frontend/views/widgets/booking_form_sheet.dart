import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';

/// A bottom-sheet booking form that collects traveler details.
/// Shows success / error feedback from the Bloc.
class BookingFormSheet extends StatefulWidget {
  final String packageId;
  final String packageTitle;
  final String guideName;
  final double pricePerPerson;
  final int availableSeats;

  const BookingFormSheet({
    super.key,
    required this.packageId,
    required this.packageTitle,
    required this.guideName,
    required this.pricePerPerson,
    required this.availableSeats,
  });

  /// Convenience helper: show the sheet from any context with TravelBloc in scope.
  static Future<void> show(
    BuildContext context, {
    required String packageId,
    required String packageTitle,
    required String guideName,
    required double pricePerPerson,
    required int availableSeats,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TravelBloc>(),
        child: BookingFormSheet(
          packageId: packageId,
          packageTitle: packageTitle,
          guideName: guideName,
          pricePerPerson: pricePerPerson,
          availableSeats: availableSeats,
        ),
      ),
    );
  }

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();

  final _contactNode = FocusNode();
  final _notesNode = FocusNode();

  final List<_TravelerEntry> _travelers = [_TravelerEntry()];

  @override
  void dispose() {
    _contactController.dispose();
    _notesController.dispose();
    _contactNode.dispose();
    _notesNode.dispose();
    for (var t in _travelers) {
      t.dispose();
    }
    super.dispose();
  }

  double get _totalAmount => widget.pricePerPerson * _travelers.length;

  void _addTraveler() {
    if (_travelers.length >= widget.availableSeats) return;
    setState(() => _travelers.add(_TravelerEntry()));
  }

  void _removeTraveler(int index) {
    if (_travelers.length <= 1) return;
    setState(() => _travelers.removeAt(index));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final travelers = _travelers
        .map((t) => {'name': t.name, 'age': t.age, 'gender': t.gender})
        .toList();

    context.read<TravelBloc>().add(
      TravelJoinRequested(
        packageId: widget.packageId,
        guideName: widget.guideName,
        travelers: travelers,
        contactNumber: _contactController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TravelBloc, TravelState>(
      listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
      listener: (ctx, state) {
        if (state.actionStatus == BookingActionStatus.success) {
          Navigator.pop(ctx); // close sheet
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                state.actionSuccessMessage ??
                    'Booking request sent! ⏳ Please wait for ${widget.guideName} to approve your booking.',
              ),
              backgroundColor: successColorDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ctx.read<TravelBloc>().add(TravelStatusReset());
        } else if (state.actionStatus == BookingActionStatus.failure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.actionError ?? 'Something went wrong'),
              backgroundColor: errorColorDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ctx.read<TravelBloc>().add(TravelStatusReset());
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: appWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: appGreyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.ms),
                    children: [
                      AppText.heading(
                        'Join Package',
                        size: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      const SizedBox(height: 4),
                      AppText.body(
                        widget.packageTitle,
                        color: appGrey,
                        size: 13,
                      ),
                      const SizedBox(height: 24),

                      // ── Travelers ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.subHeading(
                            'Travelers',
                            fontWeight: FontWeight.w800,
                            size: 16,
                          ),
                          Text(
                            '${_travelers.length} / ${widget.availableSeats} seats',
                            style: const TextStyle(
                              color: appGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        _travelers.length,
                        (i) => _TravelerForm(
                          index: i,
                          entry: _travelers[i],
                          onRemove: _travelers.length > 1
                              ? () => _removeTraveler(i)
                              : null,
                        ),
                      ),
                      if (_travelers.length < widget.availableSeats)
                        TextButton.icon(
                          onPressed: _addTraveler,
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: const Text('Add Another Traveler'),
                        ),
                      const SizedBox(height: 16),

                      // ── Contact ────────────────────────────────────────────
                      AppText.subHeading(
                        'Contact Number',
                        fontWeight: FontWeight.w700,
                        size: 15,
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _contactController,
                        focusNode: _contactNode,
                        hint: '+91 98765 43210',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_notesNode),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => (v == null || v.length < 10)
                            ? 'Enter a valid 10-digit number'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Notes ──────────────────────────────────────────────
                      AppText.subHeading(
                        'Notes (optional)',
                        fontWeight: FontWeight.w700,
                        size: 15,
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _notesController,
                        focusNode: _notesNode,
                        hint: 'Any special requirements...',
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),

                      // ── Price Summary ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: onboardingBlueVeryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.body(
                                  '${_travelers.length} × ₹${widget.pricePerPerson.toInt()}',
                                  color: appGrey,
                                  size: 13,
                                ),
                                AppText.subHeading(
                                  'Total Amount',
                                  fontWeight: FontWeight.w700,
                                  size: 14,
                                ),
                              ],
                            ),
                            AppText.heading(
                              '₹${_totalAmount.toInt()}',
                              size: 22,
                              fontWeight: FontWeight.w900,
                              color: primaryBlue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Submit ─────────────────────────────────────────────
                      BlocBuilder<TravelBloc, TravelState>(
                        buildWhen: (p, c) => p.actionStatus != c.actionStatus,
                        builder: (_, state) {
                          final isLoading =
                              state.actionStatus == BookingActionStatus.loading;
                          return ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Confirm & Join Trip',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted:
          onFieldSubmitted ?? (_) => FocusScope.of(context).nextFocus(),
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(color: appGreyLight, fontSize: 13),
        filled: true,
        fillColor: appGreyVeryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Internal data holder for a single traveler row.
class _TravelerEntry {
  String name = '';
  int age = 18;
  String gender = 'Male';
  final FocusNode nameNode = FocusNode();
  final FocusNode ageNode = FocusNode();

  void dispose() {
    nameNode.dispose();
    ageNode.dispose();
  }
}

/// A single traveler info row inside the form.
class _TravelerForm extends StatelessWidget {
  final int index;
  final _TravelerEntry entry;
  final VoidCallback? onRemove;

  const _TravelerForm({
    required this.index,
    required this.entry,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appGreyVeryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appGreyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: primaryBlue,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppText.subHeading(
                'Traveler ${index + 1}',
                size: 14,
                fontWeight: FontWeight.w700,
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: errorColor,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: entry.name,
            focusNode: entry.nameNode,
            onChanged: (v) => entry.name = v,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(entry.ageNode),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Name is required' : null,
            style: GoogleFonts.montserrat(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Full Name',
              hintStyle: GoogleFonts.montserrat(
                color: appGreyLight,
                fontSize: 12,
              ),
              filled: true,
              fillColor: appWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Age
              Expanded(
                child: TextFormField(
                  initialValue: '${entry.age}',
                  focusNode: entry.ageNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => entry.age = int.tryParse(v) ?? 18,
                  onFieldSubmitted: (_) => FocusScope.of(
                    context,
                  ).nextFocus(), // Skip dropdown to next form part
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 5) ? 'Invalid age' : null;
                  },
                  style: GoogleFonts.montserrat(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Age',
                    hintStyle: GoogleFonts.montserrat(
                      color: appGreyLight,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: appWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Gender
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: entry.gender,
                  onChanged: (v) => entry.gender = v!,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: appWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
