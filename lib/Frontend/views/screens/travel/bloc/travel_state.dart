import 'package:equatable/equatable.dart';
import 'package:yatrikaa/Frontend/core/models/travel_package_model.dart';
import 'package:yatrikaa/Frontend/core/models/booking_model.dart';
import 'package:yatrikaa/Frontend/core/models/guide_request_model.dart';

enum TravelStatus { initial, loading, success, failure }

enum BookingActionStatus { idle, loading, success, failure }

class TravelState extends Equatable {
  // ── Discovery ──────────────────────────────────────────────────────────────
  final TravelStatus packagesStatus;
  final List<TravelPackageModel> packages;
  final String selectedCategory;
  final String searchQuery;
  final String? packagesError;

  // ── Detail ─────────────────────────────────────────────────────────────────
  final TravelStatus detailStatus;
  final TravelPackageModel? selectedPackage;
  final String? detailError;

  // ── Guide: My Packages ─────────────────────────────────────────────────────
  final TravelStatus myPackagesStatus;
  final List<TravelPackageModel> myPackages;
  final int myPackagesPage;
  final bool myPackagesHasMore;

  // ── Admin: Review Queue ───────────────────────────────────────────────────
  final TravelStatus adminPackagesStatus;
  final List<TravelPackageModel> adminPackages;
  final int adminPackagesPage;
  final bool adminPackagesHasMore;

  // ── Admin: Guide Requests ──────────────────────────────────────────────────
  final TravelStatus adminGuideRequestsStatus;
  final List<GuideRequestModel> adminGuideRequests;

  // ── Guide: Booking Management ─────────────────────────────────────────────
  final TravelStatus guideBookingsStatus;
  final List<BookingModel> guideBookings;

  // ── User: Bookings ────────────────────────────────────────────────────────
  final TravelStatus bookingsStatus;
  final List<BookingModel> myBookings;
  final String? bookingsError;

  // ── Join / Cancel action ──────────────────────────────────────────────────
  final BookingActionStatus actionStatus;
  final String? actionError;
  final String? actionSuccessMessage;

  const TravelState({
    this.packagesStatus = TravelStatus.initial,
    this.packages = const [],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.packagesError,
    this.detailStatus = TravelStatus.initial,
    this.selectedPackage,
    this.detailError,
    this.myPackagesStatus = TravelStatus.initial,
    this.myPackages = const [],
    this.myPackagesPage = 1,
    this.myPackagesHasMore = false,
    this.bookingsStatus = TravelStatus.initial,
    this.myBookings = const [],
    this.bookingsError,
    this.actionStatus = BookingActionStatus.idle,
    this.actionError,
    this.actionSuccessMessage,
    this.adminPackagesStatus = TravelStatus.initial,
    this.adminPackages = const [],
    this.adminPackagesPage = 1,
    this.adminPackagesHasMore = false,
    this.adminGuideRequestsStatus = TravelStatus.initial,
    this.adminGuideRequests = const [],
    this.guideBookingsStatus = TravelStatus.initial,
    this.guideBookings = const [],
  });

  TravelState copyWith({
    TravelStatus? packagesStatus,
    List<TravelPackageModel>? packages,
    String? selectedCategory,
    String? searchQuery,
    String? packagesError,
    TravelStatus? detailStatus,
    TravelPackageModel? selectedPackage,
    String? detailError,
    TravelStatus? myPackagesStatus,
    List<TravelPackageModel>? myPackages,
    int? myPackagesPage,
    bool? myPackagesHasMore,
    TravelStatus? bookingsStatus,
    List<BookingModel>? myBookings,
    String? bookingsError,
    BookingActionStatus? actionStatus,
    String? actionError,
    String? actionSuccessMessage,
    TravelStatus? adminPackagesStatus,
    List<TravelPackageModel>? adminPackages,
    int? adminPackagesPage,
    bool? adminPackagesHasMore,
    TravelStatus? adminGuideRequestsStatus,
    List<GuideRequestModel>? adminGuideRequests,
    TravelStatus? guideBookingsStatus,
    List<BookingModel>? guideBookings,
  }) {
    return TravelState(
      packagesStatus: packagesStatus ?? this.packagesStatus,
      packages: packages ?? this.packages,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      packagesError: packagesError ?? this.packagesError,
      detailStatus: detailStatus ?? this.detailStatus,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      detailError: detailError ?? this.detailError,
      myPackagesStatus: myPackagesStatus ?? this.myPackagesStatus,
      myPackages: myPackages ?? this.myPackages,
      myPackagesPage: myPackagesPage ?? this.myPackagesPage,
      myPackagesHasMore: myPackagesHasMore ?? this.myPackagesHasMore,
      bookingsStatus: bookingsStatus ?? this.bookingsStatus,
      myBookings: myBookings ?? this.myBookings,
      bookingsError: bookingsError ?? this.bookingsError,
      actionStatus: actionStatus ?? this.actionStatus,
      actionError: actionError ?? this.actionError,
      actionSuccessMessage: actionSuccessMessage ?? this.actionSuccessMessage,
      adminPackagesStatus: adminPackagesStatus ?? this.adminPackagesStatus,
      adminPackages: adminPackages ?? this.adminPackages,
      adminPackagesPage: adminPackagesPage ?? this.adminPackagesPage,
      adminPackagesHasMore: adminPackagesHasMore ?? this.adminPackagesHasMore,
      adminGuideRequestsStatus:
          adminGuideRequestsStatus ?? this.adminGuideRequestsStatus,
      adminGuideRequests: adminGuideRequests ?? this.adminGuideRequests,
      guideBookingsStatus: guideBookingsStatus ?? this.guideBookingsStatus,
      guideBookings: guideBookings ?? this.guideBookings,
    );
  }

  /// Convenience: filter packages client-side by current search + category.
  List<TravelPackageModel> get displayPackages {
    var list = packages;
    if (selectedCategory != 'All') {
      list = list
          .where(
            (p) => p.category.toLowerCase() == selectedCategory.toLowerCase(),
          )
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.destinationName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<BookingModel> get upcomingBookings => myBookings
      .where(
        (b) =>
            b.status == 'Pending' ||
            b.status == 'Confirmed' ||
            b.status == 'CancellationRequested',
      )
      .toList();

  List<BookingModel> get completedBookings =>
      myBookings.where((b) => b.status == 'Completed').toList();

  List<BookingModel> get cancelledBookings =>
      myBookings.where((b) => b.status == 'Cancelled').toList();

  @override
  List<Object?> get props => [
    packagesStatus,
    packages,
    selectedCategory,
    searchQuery,
    packagesError,
    detailStatus,
    selectedPackage,
    detailError,
    myPackagesStatus,
    myPackages,
    myPackagesPage,
    myPackagesHasMore,
    bookingsStatus,
    myBookings,
    bookingsError,
    actionStatus,
    actionError,
    actionSuccessMessage,
    adminPackagesStatus,
    adminPackages,
    adminPackagesPage,
    adminPackagesHasMore,
    adminGuideRequestsStatus,
    adminGuideRequests,
    guideBookingsStatus,
    guideBookings,
  ];
}
