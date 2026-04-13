import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';
import 'package:yatrikaa/Frontend/core/models/post_model.dart';
import 'package:yatrikaa/Frontend/core/services/post_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:yatrikaa/Frontend/core/bloc/auth/auth_state.dart';
import 'package:yatrikaa/Frontend/views/screens/community/widgets/create_post_sheet.dart';
import 'package:yatrikaa/Frontend/views/screens/community/widgets/post_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _postService.getAllPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreatePostSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostSheet(),
    );

    if (result == true) {
      _fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.id : null;
    final currentUserRole = authState is Authenticated ? authState.role : null;

    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchPosts,
          color: primaryBlue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.ms,
                    12,
                    AppSpacing.ms,
                    16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.heading(
                            AppStrings.commJourneys,
                            fontWeight: FontWeight.w900,
                            size: 26,
                            color: appBlack,
                            letterSpacing: -0.5,
                          ),
                          const SizedBox(height: 2),
                          AppText.caption(
                            AppStrings.commSubtitle,
                            color: appGrey,
                            fontWeight: FontWeight.w500,
                            size: 13,
                          ),
                        ],
                      ),
                      _HeaderAction(
                        icon: Icons.add_rounded,
                        onTap: _showCreatePostSheet,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  ),
                )
              else if (_posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_stories_outlined,
                          size: 64,
                          color: appGreyLight,
                        ),
                        const SizedBox(height: 16),
                        AppText.body(
                          AppStrings.commNoJourneys,
                          color: appGrey,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchPosts,
                          child: const Text(AppStrings.refresh),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                   padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.ms,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return PostCard(
                        key: ValueKey(_posts[index].id),
                        post: _posts[index],
                        currentUserId: currentUserId,
                        currentUserRole: currentUserRole,
                        onUpdate: (updatedPost) {
                          if (mounted) {
                            setState(() {
                              final updateIndex = _posts.indexWhere(
                                (p) => p.id == updatedPost.id,
                              );
                              if (updateIndex != -1) {
                                _posts[updateIndex] = updatedPost;
                              }
                            });
                          }
                        },
                        onDelete: () {
                          final postId = _posts[index].id;
                          if (mounted) {
                            setState(() {
                              _posts.removeWhere((p) => p.id == postId);
                            });
                          }
                        },
                      );
                    }, childCount: _posts.length),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl + AppSpacing.l),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary ? primaryBlue : appWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? primaryBlue : appBlack).withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: isPrimary ? appWhite : primaryBlue, size: 24),
      ),
    );
  }
}
