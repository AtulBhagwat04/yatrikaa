import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/constants/api_constants.dart';
import 'package:yatrikaa/Frontend/core/services/auth_service.dart';
import 'package:yatrikaa/Frontend/views/widgets/custom_alert_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final List<dynamic> _travelers = [];
  final List<dynamic> _guides = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  final AuthService _authService = AuthService();
  late TabController _tabController;

  int _travelerPage = 1;
  int _guidePage = 1;
  bool _hasMoreTravelers = false;
  bool _hasMoreGuides = false;
  
  final ScrollController _travelerScrollController = ScrollController();
  final ScrollController _guideScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialFetch();
    _travelerScrollController.addListener(() => _onScroll('user'));
    _guideScrollController.addListener(() => _onScroll('guide'));
  }

  void _onScroll(String role) {
    final controller = role == 'user' ? _travelerScrollController : _guideScrollController;
    final hasMore = role == 'user' ? _hasMoreTravelers : _hasMoreGuides;
    
    if (controller.position.pixels >= controller.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && hasMore && !_isLoading) {
        _loadMore(role);
      }
    }
  }

  Future<void> _initialFetch() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      await Future.wait([
        _fetchUsers('user', refresh: true),
        _fetchUsers('guide', refresh: true),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _travelerScrollController.dispose();
    _guideScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers(String role, {bool refresh = false}) async {
    if (refresh) {
      if (mounted) {
        setState(() {
          _error = null;
          if (role == 'user') {
            _travelerPage = 1;
            _travelers.clear();
          } else {
            _guidePage = 1;
            _guides.clear();
          }
        });
      }
    }

    try {
      final page = role == 'user' ? _travelerPage : _guidePage;
      final result = await _authService.getUsersPaginated(role: role, page: page);
      
      debugPrint('[UserManagement] Fetched ${role}s: ${result['results']?.length} (Page: $page)');

      if (mounted) {
        setState(() {
          final newUsers = result['results'] as List<dynamic>;
          if (role == 'user') {
            _travelers.addAll(newUsers);
            _hasMoreTravelers = result['hasMore'] ?? false;
          } else {
            _guides.addAll(newUsers);
            _hasMoreGuides = result['hasMore'] ?? false;
          }
        });
      }
    } catch (e) {
      debugPrint('[UserManagement] Error fetching $role: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _loadMore(String role) async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    if (role == 'user') {
      _travelerPage++;
    } else {
      _guidePage++;
    }

    await _fetchUsers(role);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: SafeArea(
        top: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: onboardingBlueVeryLight,
                elevation: 0,
                scrolledUnderElevation: 2,
                surfaceTintColor: Colors.white,
                title: Text(
                  'User Management',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: appBlack,
                  ),
                ),
                centerTitle: true,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: primaryBlue,
                    unselectedLabelColor: appGrey,
                    indicatorColor: primaryBlue,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    labelStyle: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    tabs: const [
                      Tab(text: 'Travelers'),
                      Tab(text: 'Guides'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [_buildUserList('user'), _buildUserList('guide')],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(String role) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    final filtered = role == 'user' ? _travelers : _guides;

    if (filtered.isEmpty) {
      return _buildEmptyWidget(role);
    }

    return RefreshIndicator(
      onRefresh: () => _fetchUsers(role, refresh: true),
      color: primaryBlue,
      child: ListView.builder(
        controller: role == 'user' ? _travelerScrollController : _guideScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
        itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < filtered.length) {
            return _buildUserCard(filtered[index]);
          }
          return _buildLoadingIndicator();
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
      ),
    );
  }


  Widget _buildUserCard(dynamic user) {
    final role = user['role'] ?? 'user';
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? 'No email';
    final profilePic = user['profilePicture'];
    final initial = (name.isEmpty ? '?' : name[0]).toUpperCase();
    final color = _getRoleColor(role);

    // Stats from model
    final trips = user['tripsCount'] ?? 0;
    final reviews = user['reviewsCount'] ?? 0;
    final posts = user['postsCount'] ?? 0;
    final packages = user['packagesCount'] ?? 0;

    final isGuide = role.toLowerCase() == 'guide';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- Top Info Row ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Avatar Section ---
                    Hero(
                      tag: 'user_avatar_${user['_id']}',
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: color.withOpacity(0.08),
                          child: ClipOval(
                            child:
                                profilePic != null &&
                                    profilePic.toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: profilePic,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        _buildInitialsAvatar(
                                          initial,
                                          role,
                                          size: 30,
                                        ),
                                  )
                                : _buildInitialsAvatar(initial, role, size: 30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // --- User Details ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: appBlack,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (role == 'guide') ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: primaryBlue,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 14,
                                color: appGrey.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  email,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: appGrey.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPremiumRoleChip(role),
                        ],
                      ),
                    ),

                    // --- Action Menu ---
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: appGrey.withOpacity(0.5),
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 10,
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              _buildActionIcon(
                                Icons.visibility_rounded,
                                primaryBlue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'View Full Profile',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              _buildActionIcon(
                                Icons.delete_sweep_rounded,
                                errorColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Deactivate Account',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'delete') {
                          _confirmDeletion(user['_id'], name);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Data Dashboard ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: onboardingBlueLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appWhite, width: 2),
                  ),
                  child: Row(
                    children: [
                      _buildSummaryStat(
                        trips.toString(),
                        'Trips Done',
                        Icons.airplane_ticket,
                        color,
                      ),
                      _buildSummaryDivider(),
                      _buildSummaryStat(
                        posts.toString(),
                        'Posts',
                        Icons.collections_rounded,
                        color,
                      ),
                      _buildSummaryDivider(),
                      _buildSummaryStat(
                        isGuide ? packages.toString() : reviews.toString(),
                        isGuide ? 'Packages' : 'Reviews',
                        isGuide
                            ? Icons.inventory_2_outlined
                            : Icons.auto_awesome_rounded,
                        color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRoleChip(String role) {
    final color = _getRoleColor(role);
    final label = role == 'user' ? 'Traveler' : role.toUpperCase();
    final icon = role == 'guide' ? Icons.stars_rounded : Icons.explore_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: appBlack,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: appGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: appGrey.withValues(alpha: 0.1),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildInitialsAvatar(String initial, String role, {double size = 22}) {
    final color = _getRoleColor(role);
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: color.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: GoogleFonts.montserrat(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: errorColor),
            const SizedBox(height: 16),
            AppText.body('Something went wrong', fontWeight: FontWeight.bold),
            const SizedBox(height: 8),
            AppText.caption(_error!, color: appGrey, align: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initialFetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String role) {
    String label = role == 'all' ? 'No users found' : 'No ${role}s found';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 80,
            color: primaryBlue.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          AppText.body(label, color: appGrey),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    String r = role.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (r == 'admin') return adminColor;
    if (r == 'guide') return guideColor;
    return primaryBlue;
  }

  void _confirmDeletion(String userId, String userName) {
    CustomAlertDialog.show(
      context,
      title: 'Delete User',
      message:
          'Are you sure you want to delete user "$userName"? This action cannot be undone.',
      confirmLabel: 'Delete',
      type: CustomAlertType.error,
      onConfirm: () => _deleteUser(userId),
    );
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/auth/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _travelers.removeWhere((u) => u['_id'] == userId);
            _guides.removeWhere((u) => u['_id'] == userId);
            _isLoading = false;
          });
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete user');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + 10;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 10;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: onboardingBlueVeryLight,
      padding: const EdgeInsets.only(bottom: 10),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
