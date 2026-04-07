import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/models/booking_model.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';

class BookingRequestsScreen extends StatefulWidget {
  final String? packageId;

  const BookingRequestsScreen({super.key, this.packageId});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.packageId != null) {
      context.read<TravelBloc>().add(
        TravelPackageParticipantsRequested(widget.packageId!),
      );
    } else {
      context.read<TravelBloc>().add(TravelAllGuideBookingsRequested());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TravelBloc, TravelState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == BookingActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage ?? 'Action successful'),
              backgroundColor: successColorDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (widget.packageId != null) {
            context.read<TravelBloc>().add(
              TravelPackageParticipantsRequested(widget.packageId!),
            );
          } else {
            context.read<TravelBloc>().add(TravelAllGuideBookingsRequested());
          }
          context.read<TravelBloc>().add(TravelStatusReset());
        } else if (state.actionStatus == BookingActionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError ?? 'Action failed'),
              backgroundColor: errorColorDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<TravelBloc>().add(TravelStatusReset());
        }
      },
      child: Scaffold(
        backgroundColor: onboardingBlueVeryLight,
        appBar: AppBar(
          backgroundColor: onboardingBlueVeryLight,
          elevation: 0,
          title: AppText.subHeading(
            widget.packageId != null ? 'Package Bookings' : 'All Bookings',
            fontWeight: FontWeight.w900,
            color: appBlack,
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: primaryBlue,
            unselectedLabelColor: appGrey,
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Joining'),
              Tab(text: 'Cancellations'),
            ],
          ),
        ),
        body: BlocBuilder<TravelBloc, TravelState>(
          buildWhen: (p, c) =>
              p.guideBookingsStatus != c.guideBookingsStatus ||
              p.guideBookings != c.guideBookings,
          builder: (context, state) {
            if (state.guideBookingsStatus == TravelStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.guideBookingsStatus == TravelStatus.failure) {
              return _buildErrorState();
            }

            final bookings = state.guideBookings;

            // Categorize bookings for tabs
            final joiningList =
                bookings
                    .where(
                      (b) => b.status == 'Pending' || b.status == 'Confirmed',
                    )
                    .toList()
                  ..sort((a, b) {
                    // Pending first
                    if (a.status == 'Pending' && b.status != 'Pending') {
                      return -1;
                    }
                    if (a.status != 'Pending' && b.status == 'Pending') {
                      return 1;
                    }
                    return 0;
                  });

            final cancellationList = bookings.where((b) {
              final hasTravelerReq = b.travelers.any(
                (t) => t.status == 'CancellationRequested',
              );
              return b.status == 'CancellationRequested' ||
                  b.status == 'Cancelled' ||
                  hasTravelerReq;
            }).toList()
                  ..sort((a, b) {
                    final aHasTravelerReq = a.travelers.any(
                      (t) => t.status == 'CancellationRequested',
                    );
                    final bHasTravelerReq = b.travelers.any(
                      (t) => t.status == 'CancellationRequested',
                    );
                    final aUrgent =
                        a.status == 'CancellationRequested' || aHasTravelerReq;
                    final bUrgent =
                        b.status == 'CancellationRequested' || bHasTravelerReq;

                    if (aUrgent && !bUrgent) return -1;
                    if (!aUrgent && bUrgent) return 1;
                    return 0;
                  });

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTabList(joiningList, 'No joining requests yet.'),
                _buildTabList(
                  cancellationList,
                  'No cancellation requests yet.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabList(List<BookingModel> bookings, String emptyMsg) {
    if (bookings.isEmpty) {
      return _buildEmptyState(emptyMsg);
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.packageId != null) {
          context.read<TravelBloc>().add(
            TravelPackageParticipantsRequested(widget.packageId!),
          );
        } else {
          context.read<TravelBloc>().add(TravelAllGuideBookingsRequested());
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: primaryBlue,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          AppText.subHeading('No Bookings Yet', fontWeight: FontWeight.w800),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText.body(
              message,
              align: TextAlign.center,
              color: appGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: errorColor, size: 64),
          const SizedBox(height: 16),
          AppText.subHeading(
            'Something went wrong',
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (widget.packageId != null) {
                context.read<TravelBloc>().add(
                  TravelPackageParticipantsRequested(widget.packageId!),
                );
              } else {
                context.read<TravelBloc>().add(
                  TravelAllGuideBookingsRequested(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'Confirmed':
        return successColorDark;
      case 'Pending':
        return Colors.orange;
      case 'CancellationRequested':
        return Colors.deepOrange;
      case 'Cancelled':
        return errorColorDark;
      default:
        return appGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appBlack.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (booking.status == 'CancellationRequested')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            AppText.small(
                              'CANCELLATION REQUEST',
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w900,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AppText.small(
                          booking.status.toUpperCase(),
                          color: _statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    AppText.small(
                      DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                      color: appGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppText.body(
                  booking.packageTitle,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  size: 15,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.body(
                            booking.userName ?? 'Yatrikaa Traveler',
                            fontWeight: FontWeight.w800,
                          ),
                          const SizedBox(height: 2),
                          AppText.small(
                            'Contact: ${booking.contactNumber}',
                            color: appGrey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ────────────────── TRAVELERS LIST (EXPANDABLE) ──────────────────
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    collapsedIconColor: primaryBlue,
                    iconColor: primaryBlue,
                    title: Row(
                      children: [
                        Text(
                          'TRAVELERS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: appGrey.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText.small(
                            '${booking.travelers.length}',
                            color: primaryBlue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: booking.travelers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final t = booking.travelers[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: onboardingBlueVeryLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryBlue.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: AppText.small(
                                      '${i + 1}',
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText.small(
                                        t.name.toUpperCase(),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            t.gender.toLowerCase() == 'male'
                                                ? Icons.male_rounded
                                                : t.gender.toLowerCase() == 'female'
                                                ? Icons.female_rounded
                                                : Icons.person_outline_rounded,
                                            size: 12,
                                            color: appGrey,
                                          ),
                                          const SizedBox(width: 4),
                                          AppText.caption(
                                            '${t.gender} • ${t.age} yrs',
                                            color: appGrey,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                 if ((t.status == 'Pending' ||
                                         t.status == 'CancellationRequested') &&
                                     booking.status !=
                                         'CancellationRequested') ...[
                                   if (t.status == 'CancellationRequested')
                                     Padding(
                                       padding: const EdgeInsets.only(right: 8),
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(
                                           horizontal: 6,
                                           vertical: 2,
                                         ),
                                         decoration: BoxDecoration(
                                           color: Colors.red.withOpacity(0.1),
                                           borderRadius:
                                               BorderRadius.circular(4),
                                         ),
                                         child: Row(
                                           children: [
                                             const Icon(
                                               Icons.warning_amber_rounded,
                                               size: 10,
                                               color: Colors.red,
                                             ),
                                             const SizedBox(width: 4),
                                             AppText.small(
                                               'CANCEL REQ.',
                                               color: Colors.red,
                                               size: 8,
                                               fontWeight: FontWeight.w900,
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   IconButton(
                                     icon: const Icon(
                                       Icons.close_rounded,
                                       color: errorColor,
                                       size: 20,
                                     ),
                                     onPressed: () =>
                                         _handleTraveler(context, t.id, 'Cancelled'),
                                     padding: EdgeInsets.zero,
                                     constraints: const BoxConstraints(),
                                   ),
                                   const SizedBox(width: 8),
                                   IconButton(
                                     icon: const Icon(
                                       Icons.check_rounded,
                                       color: successColorDark,
                                       size: 20,
                                     ),
                                     onPressed: () =>
                                         _handleTraveler(context, t.id, 'Confirmed'),
                                     padding: EdgeInsets.zero,
                                     constraints: const BoxConstraints(),
                                   ),
                                 ] else ...[
                                   Container(
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 8,
                                       vertical: 2,
                                     ),
                                     decoration: BoxDecoration(
                                       color: (t.status == 'Confirmed'
                                               ? successColorDark
                                               : (t.status == 'CancellationRequested'
                                                   ? Colors.orange
                                                   : errorColorDark))
                                           .withOpacity(0.1),
                                       borderRadius: BorderRadius.circular(6),
                                     ),
                                     child: AppText.caption(
                                       t.status,
                                       color: t.status == 'Confirmed'
                                           ? successColorDark
                                           : (t.status == 'CancellationRequested'
                                               ? Colors.deepOrange
                                               : errorColorDark),
                                       fontWeight: FontWeight.w800,
                                     ),
                                   ),
                                 ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: onboardingBlueVeryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 16,
                          color: appGrey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText.small(booking.notes!, color: appGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (booking.status == 'Pending' ||
              booking.status == 'CancellationRequested') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      context,
                      booking.status == 'CancellationRequested'
                          ? 'Keep Booking'
                          : 'Reject',
                      booking.status == 'CancellationRequested'
                          ? primaryBlue
                          : errorColorDark,
                      () => _handleBooking(
                        context,
                        booking.status == 'CancellationRequested'
                            ? 'Confirmed'
                            : 'Cancelled',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      context,
                      booking.status == 'CancellationRequested'
                          ? 'Approve Cancel'
                          : 'Approve',
                      booking.status == 'CancellationRequested'
                          ? errorColorDark
                          : successColorDark,
                      () => _handleBooking(
                        context,
                        booking.status == 'CancellationRequested'
                            ? 'Cancelled'
                            : 'Confirmed',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleBooking(BuildContext context, String action) {
    context.read<TravelBloc>().add(
      TravelHandleBookingRequested(bookingId: booking.id, action: action),
    );
  }

  void _handleTraveler(BuildContext context, String travelerId, String status) {
    context.read<TravelBloc>().add(
      TravelHandleTravelerStatusRequested(
        bookingId: booking.id,
        travelerId: travelerId,
        status: status,
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: AppText.body(
              label,
              color: color,
              fontWeight: FontWeight.w800,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}
