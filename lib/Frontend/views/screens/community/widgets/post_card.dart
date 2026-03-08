import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bhatkanti_app/Frontend/core/models/post_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/post_service.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/views/screens/community/widgets/comments_sheet.dart';
import 'package:bhatkanti_app/Frontend/views/screens/community/widgets/post_detail_popup.dart';

import 'package:bhatkanti_app/Frontend/views/screens/community/widgets/edit_post_sheet.dart';
import 'package:bhatkanti_app/Frontend/core/widgets/custom_toast.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final Function(PostModel) onUpdate;
  final VoidCallback onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked =
        widget.currentUserId != null &&
        widget.post.likes.contains(widget.currentUserId);
    _likeCount = widget.post.likes.length;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.likes != widget.post.likes) {
      _isLiked =
          widget.currentUserId != null &&
          widget.post.likes.contains(widget.currentUserId);
      _likeCount = widget.post.likes.length;
    }
  }

  void _handleLike() async {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_isLiked) {
        _likeCount--;
      } else {
        _likeCount++;
      }
      _isLiked = !_isLiked;
    });

    final updatedPost = await PostService().likePost(widget.post.id);
    if (updatedPost != null) {
      widget.onUpdate(updatedPost);
    } else {
      if (mounted) {
        setState(() {
          _isLiked =
              widget.currentUserId != null &&
              widget.post.likes.contains(widget.currentUserId);
          _likeCount = widget.post.likes.length;
        });
      }
    }
  }

  void _handleShare() {
    Share.share(
      'Check out this journey at ${widget.post.location} by ${widget.post.author.name}!\n\n"${widget.post.caption}"\n\nShared via Bhatkanti App',
    );
  }

  void _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text(
          "Are you sure you want to delete this journey? This action cannot be undone.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) CustomToast.progress(context, "Deleting post...");
      final success = await PostService().deletePost(widget.post.id);
      if (success) {
        if (mounted) {
          CustomToast.success(context, "Post deleted successfully");
          widget.onDelete();
        }
      } else {
        if (mounted) CustomToast.error(context, "Failed to delete post");
      }
    }
  }

  void _handleEdit() async {
    final updatedPost = await showModalBottomSheet<PostModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPostSheet(post: widget.post),
    );

    if (updatedPost != null) {
      widget.onUpdate(updatedPost);
    }
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: appGreyVeryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              title: const Text(
                "Edit Journey",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleEdit();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: errorColor,
                  size: 20,
                ),
              ),
              title: const Text(
                "Delete Journey",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: errorColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleDelete();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openDetailedPopUp() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppStrings.commPostDetail,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PostDetailPopUp(
              post: widget.post,
              currentUserId: widget.currentUserId,
              onLike: () {
                _handleLike();
                setDialogState(() {});
              },
              onShare: _handleShare,
              onComment: (ctx) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CommentsSheet(
                    post: widget.post,
                    currentUserId: widget.currentUserId,
                    onUpdate: (updatedPost) {
                      widget.onUpdate(updatedPost);
                      setDialogState(() {});
                    },
                  ),
                );
              },
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(scale: anim1, child: child);
      },
    );
  }

  String _timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 7) {
      return '${(duration.inDays / 7).floor()}${AppStrings.commWeeksAgo}';
    }
    if (duration.inDays > 0) {
      return '${duration.inDays}${AppStrings.commDaysAgo}';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}${AppStrings.commHoursAgo}';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}${AppStrings.commMinutesAgo}';
    }
    return AppStrings.commJustNow;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: appWhite,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: shadowColorLight,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openDetailedPopUp,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: p.imageUrl,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: appGreyVeryLight, height: 260),
                          errorWidget: (context, url, error) => Container(
                            color: appGreyVeryLight,
                            height: 260,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: appGrey,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: overlayColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: appWhite,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.location,
                                  style: const TextStyle(
                                    color: appWhite,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: primaryBlue.withOpacity(0.1),
                            child: Text(
                              p.author.name.isNotEmpty ? p.author.name[0] : '?',
                              style: const TextStyle(
                                color: primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppText.body(
                            p.author.name,
                            fontWeight: FontWeight.w700,
                            size: 13,
                          ),
                          const Spacer(),
                          AppText.caption(_timeAgo(p.createdAt), size: 10),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppText.body(
                        p.caption,
                        size: 13,
                        color: appGreyDark,
                        height: 1.5,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                _PillButton(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '$_likeCount',
                  active: _isLiked,
                  activeColor: Colors.redAccent,
                  onTap: _handleLike,
                ),
                const SizedBox(width: 12),
                _PillButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${p.comments.length}',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsSheet(
                        post: widget.post,
                        onUpdate: widget.onUpdate,
                        currentUserId: widget.currentUserId,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _PillButton(
                  icon: Icons.share_outlined,
                  label: AppStrings.commShare,
                  onTap: _handleShare,
                ),
                if (widget.currentUserId == p.author.id) ...[
                  const Spacer(),
                  IconButton(
                    onPressed: _showPostOptions,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 22,
                      color: appGrey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? (activeColor ?? primaryBlue) : appGrey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.08) : appGreyVeryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
