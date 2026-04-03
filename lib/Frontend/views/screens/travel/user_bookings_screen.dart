import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';
import 'package:bhatkanti_app/Frontend/core/models/booking_model.dart';
import 'package:bhatkanti_app/Frontend/views/Routes/route_names.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:bhatkanti_app/Frontend/views/screens/travel/bloc/travel_state.dart';
import 'package:bhatkanti_app/Frontend/views/widgets/custom_alert_dialog.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<TravelBloc>().add(TravelMyBookingsRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      buildWhen: (p, c) =>
          p.bookingsStatus != c.bookingsStatus || p.myBookings != c.myBookings,
      builder: (ctx, state) {
        return Scaffold(
          backgroundColor: onboardingBlueVeryLight,
          appBar: AppBar(
            backgroundColor: onboardingBlueVeryLight,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: AppText.subHeading(
              'My Trips',
              fontWeight: FontWeight.w800,
              size: 20,
            ),
            centerTitle: true,
            actions: [
              if (state.bookingsStatus == TravelStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
                  onPressed: () =>
                      ctx.read<TravelBloc>().add(TravelMyBookingsRequested()),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: primaryBlue,
              unselectedLabelColor: appGrey,
              indicatorColor: primaryBlue,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Upcoming'),
                      if (state.upcomingBookings.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _badge(state.upcomingBookings.length, primaryBlue),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Completed'),
                const Tab(text: 'Cancelled'),
              ],
            ),
          ),
          body: state.bookingsStatus == TravelStatus.failure
              ? _buildError(ctx)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(ctx, state.upcomingBookings, 'upcoming'),
                    _buildList(ctx, state.completedBookings, 'completed'),
                    _buildList(ctx, state.cancelledBookings, 'cancelled'),
                  ],
                ),
        );
      },
    );
  }

  Widget _badge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext ctx,
    List<BookingModel> bookings,
    String type,
  ) {
    if (bookings.isEmpty) return _buildEmpty(ctx, type);
    return RefreshIndicator(
      onRefresh: () async =>
          ctx.read<TravelBloc>().add(TravelMyBookingsRequested()),
      color: primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.ms),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _BookingCard(
          booking: bookings[i],
          onCancel: type == 'upcoming'
              ? () => _confirmCancel(ctx, bookings[i].id)
              : null,
          onViewDetails: () => Navigator.pushNamed(
            ctx,
            RouteNames.packageDetails,
            arguments: bookings[i].packageId,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext ctx, String type) {
    final messages = {
      'upcoming':
          'You have no upcoming trips.\nBrowse packages and start an adventure!',
      'completed':
          'No completed trips yet.\nThey\'ll appear here after your journey.',
      'cancelled': 'No cancelled bookings.',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: Icon(
              type == 'upcoming'
                  ? Icons.map_outlined
                  : type == 'completed'
                  ? Icons.task_alt_rounded
                  : Icons.cancel_outlined,
              color: primaryBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          AppText.heading('No ${_capitalize(type)} Trips', size: 20),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText.body(
              messages[type] ?? '',
              align: TextAlign.center,
              color: Colors.grey,
              size: 13,
            ),
          ),
          if (type == 'upcoming') ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(ctx, RouteNames.packages),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text(
                'Explore Packages',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: appGreyLight),
          const SizedBox(height: 16),
          AppText.subHeading(
            'Could not load trips',
            color: appGrey,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ctx.read<TravelBloc>().add(TravelMyBookingsRequested()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext ctx, String bookingId) {
    CustomAlertDialog.show(
      ctx,
      title: 'Cancel Booking?',
      message: 'Are you sure you want to cancel this trip booking?',
      confirmLabel: 'Cancel Booking',
      cancelLabel: 'Keep it',
      type: CustomAlertType.error,
      icon: Icons.event_busy_rounded,
      onConfirm: () {
        ctx.read<TravelBloc>().add(TravelCancelBookingRequested(bookingId));
      },
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onCancel;
  final VoidCallback? onViewDetails;

  const _BookingCard({
    required this.booking,
    this.onCancel,
    this.onViewDetails,
  });

  Color get _statusColor {
    switch (booking.status) {
      case 'Confirmed':
        return successColorDark;
      case 'Pending':
        return warningColorDark;
      case 'CancellationRequested':
        return Colors.deepOrange;
      case 'Completed':
        return primaryBlue;
      case 'Cancelled':
        return errorColorDark;
      default:
        return appGrey;
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case 'Confirmed':
        return Icons.check_circle_rounded;
      case 'Pending':
        return Icons.hourglass_empty_rounded;
      case 'CancellationRequested':
        return Icons.schedule_send_rounded;
      case 'Completed':
        return Icons.task_alt_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _statusColor.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(_statusIcon, size: 14, color: _statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.status == 'CancellationRequested' 
                          ? 'Cancellation Requested' 
                          : booking.status,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText.subHeading(
                          booking.packageTitle.isNotEmpty
                              ? booking.packageTitle
                              : 'Unknown Package',
                          size: 15,
                          fontWeight: FontWeight.w800,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppText.subHeading(
                        '₹${booking.totalAmount.toInt()}',
                        size: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (booking.destinationName.isNotEmpty)
                    _row(Icons.location_on_outlined, booking.destinationName),
                  _row(
                    Icons.calendar_today_outlined,
                    _formatDate(booking.bookingDate),
                  ),
                  if (booking.organiserName.isNotEmpty)
                    _row(
                      Icons.person_outline_rounded,
                      'By ${booking.organiserName}',
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onViewDetails,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (booking.status == 'Completed') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ratingColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Write Review',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ] else if (onCancel != null &&
                          booking.status != 'CancellationRequested') ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: TextButton(
                            onPressed: onCancel,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: errorColorDark,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: appGrey),
          const SizedBox(width: 6),
          Expanded(child: AppText.body(text, size: 12, color: appGrey)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
