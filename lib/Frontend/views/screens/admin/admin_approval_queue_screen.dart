import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/core/models/guide_request_model.dart';
import 'package:yatrikaa/Frontend/views/Routes/route_names.dart';
import 'package:yatrikaa/Frontend/views/widgets/custom_alert_dialog.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_bloc.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_event.dart';
import 'package:yatrikaa/Frontend/views/screens/travel/bloc/travel_state.dart';

class AdminApprovalQueueScreen extends StatefulWidget {
  const AdminApprovalQueueScreen({super.key});

  @override
  State<AdminApprovalQueueScreen> createState() =>
      _AdminApprovalQueueScreenState();
}

class _AdminApprovalQueueScreenState extends State<AdminApprovalQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    context.read<TravelBloc>().add(
      const TravelAdminReviewRequested(status: 'Draft'),
    );
    context.read<TravelBloc>().add(TravelGuideRequestsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TravelBloc, TravelState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: (ctx, state) {
        if (state.actionStatus == BookingActionStatus.success &&
            state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: successColorDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ctx.read<TravelBloc>().add(TravelStatusReset());
        } else if (state.actionStatus == BookingActionStatus.failure &&
            state.actionError != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: errorColorDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ctx.read<TravelBloc>().add(TravelStatusReset());
        }
      },
      child: Scaffold(
        backgroundColor: onboardingBlueVeryLight,
        appBar: AppBar(
          backgroundColor: onboardingBlueVeryLight,
          elevation: 0,
          title: AppText.subHeading(
            'Approval Queue',
            fontWeight: FontWeight.w800,
            size: 20,
          ),
          centerTitle: true,
          actions: const [],
          bottom: TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(vertical: 8),
            labelColor: primaryBlue,
            unselectedLabelColor: appGrey,
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Packages'),
              Tab(text: 'Guide Requests'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_PackageApprovalQueue(), _GuideApprovalQueue()],
        ),
      ),
    );
  }
}

class _PackageApprovalQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      builder: (ctx, state) {
        debugPrint(
          'AdminApprovalQueue: adminPackagesStatus=${state.adminPackagesStatus}, drafts=${state.adminPackages.length}',
        );
        if (state.adminPackagesStatus == TravelStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        if (state.adminPackagesStatus == TravelStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: errorColor,
                ),
                const SizedBox(height: 16),
                AppText.body('Failed to load packages', color: appGrey),
                TextButton(
                  onPressed: () => context.read<TravelBloc>().add(
                    const TravelAdminReviewRequested(status: 'Draft'),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final drafts = state.adminPackages
            .where((p) => p.status == 'Draft')
            .toList();
        final hasMore = state.adminPackagesHasMore;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TravelBloc>().add(
              const TravelAdminReviewRequested(status: 'Draft'),
            );
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: drafts.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const _EmptyQueue(
                      icon: Icons.tour_rounded,
                      title: 'No Pending Packages',
                      subtitle:
                          'All package submission requests have been processed.',
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.ms),
                  itemCount: drafts.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    if (i == drafts.length) {
                      return _buildLoadMore(context);
                    }
                    return _PackageReviewCard(package: drafts[i]);
                  },
                ),
        );
      },
    );
  }

  Widget _buildLoadMore(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () => context.read<TravelBloc>().add(
              const TravelLoadMoreAdminPackages(status: 'Draft'),
            ),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        label: AppText.body("Show More Packages", fontWeight: FontWeight.bold),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: primaryBlue.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _GuideApprovalQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelBloc, TravelState>(
      builder: (ctx, state) {
        debugPrint(
          'AdminApprovalQueue: adminGuideRequestsStatus=${state.adminGuideRequestsStatus}, requests=${state.adminGuideRequests.length}',
        );
        if (state.adminGuideRequestsStatus == TravelStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        if (state.adminGuideRequestsStatus == TravelStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: errorColor,
                ),
                const SizedBox(height: 16),
                AppText.body('Failed to load guide requests', color: appGrey),
                TextButton(
                  onPressed: () => context.read<TravelBloc>().add(
                    TravelGuideRequestsRequested(),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final requests = state.adminGuideRequests;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TravelBloc>().add(TravelGuideRequestsRequested());
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: requests.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const _EmptyQueue(
                      icon: Icons.person_add_rounded,
                      title: 'No Pending Guides',
                      subtitle:
                          'All guide registration requests have been cleared.',
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.ms),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) =>
                      _GuideRequestCard(request: requests[i]),
                ),
        );
      },
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyQueue({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: appGreyLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          AppText.subHeading(
            title,
            size: 20,
            fontWeight: FontWeight.w800,
            color: appBlack,
          ),
          const SizedBox(height: 8),
          AppText.body(subtitle, color: appGrey, align: TextAlign.center),
        ],
      ),
    );
  }
}

class _PackageReviewCard extends StatelessWidget {
  final TravelPackageModel package;
  const _PackageReviewCard({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: appGreyVeryLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: package.mainPhotoUrl,
                      width: 85,
                      height: 85,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ratingColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AppText.small(
                          'PENDING REVIEW',
                          color: ratingColor,
                          fontWeight: FontWeight.w800,
                          size: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        package.title,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: appBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_pin_rounded,
                            size: 14,
                            color: guideColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'By ${package.organizer.name}',
                              style: GoogleFonts.montserrat(
                                color: guideColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: appGreyVeryLight),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.packageDetails,
                      arguments: package.id,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: appGrey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      'Details',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  color: appGreyVeryLight,
                  thickness: 1,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _confirmPublish(context),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPublish(BuildContext context) {
    CustomAlertDialog.show(
      context,
      title: 'Approve Package',
      message:
          'Are you sure you want to approve "${package.title}" and make it live for all users?',
      confirmLabel: 'Approve',
      icon: Icons.publish_rounded,
      onConfirm: () {
        context.read<TravelBloc>().add(
          TravelPublishPackageRequested(package.id),
        );
      },
    );
  }
}

class _GuideRequestCard extends StatelessWidget {
  final GuideRequestModel request;
  const _GuideRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onboardingBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: appBlack.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Larger, more professional Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    request.name.isNotEmpty
                        ? request.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: appBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.email,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: appGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'PENDING',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Data Point Section
          Row(
            children: [
              _buildDataChip(
                Icons.calendar_today_rounded,
                'Applied: ${DateFormat('dd MMM').format(request.createdAt)}',
              ),
              const SizedBox(width: 8),
              _buildDataChip(Icons.shield_outlined, 'Identity Pending'),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: onboardingBlueLight),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleRequest(context, 'reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  color: onboardingBlueLight,
                  thickness: 1,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleRequest(context, 'approve'),
                    style: TextButton.styleFrom(
                      foregroundColor: successColorDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appGreyVeryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: appGreyDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: appGreyDark,
            ),
          ),
        ],
      ),
    );
  }

  void _handleRequest(BuildContext context, String action) {
    final bool isApprove = action == 'approve';
    CustomAlertDialog.show(
      context,
      title: isApprove ? 'Verify Guide' : 'Reject Request',
      message:
          'Are you sure you want to $action ${request.name} as a verified guide in the system?',
      confirmLabel: isApprove ? 'Approve' : 'Reject',
      type: isApprove ? CustomAlertType.success : CustomAlertType.error,
      onConfirm: () {
        context.read<TravelBloc>().add(
          TravelHandleGuideRequested(userId: request.userId, action: action),
        );
      },
    );
  }
}
