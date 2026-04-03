import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/models/post_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/post_service.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_bloc.dart';
import 'package:bhatkanti_app/Frontend/core/bloc/auth/auth_state.dart';
import 'package:bhatkanti_app/Frontend/views/screens/community/widgets/post_card.dart';
import 'package:bhatkanti_app/Frontend/core/services/auth_service.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final PostService _postService = PostService();
  List<PostModel> _myPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final allPosts = await _postService.getAllPosts();
      final userId = await AuthService().getUserId();

      if (mounted) {
        setState(() {
          _myPosts = allPosts.where((p) => p.author.id == userId).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.id : null;
    final currentUserRole = authState is Authenticated ? authState.role : null;

    return Scaffold(
      backgroundColor: onboardingBlueVeryLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: onboardingBlueVeryLight,
        elevation: 0,
        title: AppText.subHeading(
          'My Posts',
          color: appBlack,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myPosts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchMyPosts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myPosts.length,
                itemBuilder: (context, index) {
                  final post = _myPosts[index];
                  return PostCard(
                    post: post,
                    currentUserId: currentUserId,
                    currentUserRole: currentUserRole,
                    onUpdate: (updatedPost) {
                      if (mounted) {
                        setState(() {
                          final updateIndex = _myPosts.indexWhere(
                            (p) => p.id == updatedPost.id,
                          );
                          if (updateIndex != -1) {
                            _myPosts[updateIndex] = updatedPost;
                          }
                        });
                      }
                    },
                    onDelete: () {
                      if (mounted) {
                        setState(() {
                          _myPosts.removeWhere((p) => p.id == post.id);
                        });
                      }
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(
              Icons.grid_view_rounded,
              color: primaryBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          AppText.heading('No Posts Yet', size: 20),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AppText.body(
              'You haven\'t shared any journeys yet. Start sharing your adventures with the community!',
              align: TextAlign.center,
              color: Colors.grey,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
