import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yatrikaa/Frontend/core/models/post_model.dart';
import 'package:yatrikaa/Frontend/core/services/post_service.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/views/screens/community/widgets/comments_sheet.dart';
import 'package:yatrikaa/Frontend/views/screens/community/widgets/post_detail_popup.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:yatrikaa/Frontend/views/screens/community/widgets/edit_post_sheet.dart';
import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:yatrikaa/Frontend/views/widgets/custom_alert_dialog.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final String? currentUserRole;
  final Function(PostModel) onUpdate;
  final VoidCallback onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.currentUserRole,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  Timer? _debounceTimer;
  StateSetter? _dialogRebuildCallback;

  @override
  void initState() {
    super.initState();
    _isLiked =
        widget.currentUserId != null &&
        widget.post.likes.contains(widget.currentUserId);
    _likeCount = widget.post.likes.length;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_debounceTimer == null) {
      final newIsLiked =
          widget.currentUserId != null &&
          widget.post.likes.contains(widget.currentUserId);
      final newLikeCount = widget.post.likes.length;

      if (newIsLiked != _isLiked || newLikeCount != _likeCount) {
        setState(() {
          _isLiked = newIsLiked;
          _likeCount = newLikeCount;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _dialogRebuildCallback?.call(() {});
        });
      }
    }
  }

  void _handleLike() async {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isLiked) {
        _likeCount--;
      } else {
        _likeCount++;
      }
      _isLiked = !_isLiked;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final initialIsLiked =
          widget.currentUserId != null &&
          widget.post.likes.contains(widget.currentUserId);

      if (_isLiked != initialIsLiked) {
        try {
          final updatedPost = await PostService().likePost(widget.post.id);
          _debounceTimer = null;
          if (updatedPost != null) {
            widget.onUpdate(updatedPost);
          } else {
            _rollbackLike();
          }
        } catch (e) {
          _debounceTimer = null;
          _rollbackLike();
        }
      } else {
        _debounceTimer = null;
      }
    });
  }

  void _rollbackLike() {
    if (mounted) {
      setState(() {
        _isLiked =
            widget.currentUserId != null &&
            widget.post.likes.contains(widget.currentUserId);
        _likeCount = widget.post.likes.length;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dialogRebuildCallback?.call(() {});
      });
    }
  }

  void _handleShare() {
    Share.share(
      'Check out this journey at ${widget.post.location} by ${widget.post.author.name}!\n\n"${widget.post.caption}"\n\nShared via Yatrikaa App',
    );
  }

  void _handleDelete() async {
    CustomAlertDialog.show(
      context,
      title: 'Delete Post',
      message:
          'Are you sure you want to delete this journey? This action cannot be undone.',
      confirmLabel: 'Delete',
      type: CustomAlertType.error,
      icon: Icons.delete_forever_rounded,
      onConfirm: () async {
        CustomToast.progress(context, "Deleting post...");
        final success = await PostService().deletePost(widget.post.id);
        if (success) {
          if (mounted) {
            CustomToast.success(context, "Post deleted successfully");
            widget.onDelete();
          }
        } else {
          if (mounted) CustomToast.error(context, "Failed to delete post");
        }
      },
    );
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
    FocusManager.instance.primaryFocus?.unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: appWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appGreyLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.edit_outlined,
              label: "Edit Journey",
              iconColor: primaryBlue,
              onTap: () {
                Navigator.pop(context);
                _handleEdit();
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: "Delete Journey",
              iconColor: errorColor,
              onTap: () {
                Navigator.pop(context);
                _handleDelete();
              },
              isDestructive: true,
            ),
            const SizedBox(height: 32),
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
            _dialogRebuildCallback = setDialogState;
            return PostDetailPopUp(
              post: widget.post,
              currentUserId: widget.currentUserId,
              currentUserRole: widget.currentUserRole,
              isLiked: _isLiked,
              likeCount: _likeCount,
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
                    currentUserRole: widget.currentUserRole,
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
    ).then((_) {
      _dialogRebuildCallback = null;
    });
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
                          imageUrl: p.primaryImageUrl,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: appGreyVeryLight, height: 260),
                          errorWidget: (context, url, error) => Container(
                            color: appGreyVeryLight,
                            height: 260,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: appGrey,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    "Image Not Available",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: appGrey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
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
                          Row(
                            children: [
                              if (p.isEdited) ...[
                                AppText.caption(
                                  "edited • ",
                                  size: 10,
                                  color: appGrey,
                                ),
                              ],
                              AppText.caption(
                                _timeAgo(
                                  p.isEdited && p.editedAt != null
                                      ? p.editedAt!
                                      : p.createdAt,
                                ),
                                size: 10,
                              ),
                            ],
                          ),
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
                    FocusManager.instance.primaryFocus?.unfocus();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsSheet(
                        post: widget.post,
                        onUpdate: widget.onUpdate,
                        currentUserId: widget.currentUserId,
                        currentUserRole: widget.currentUserRole,
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
                if (widget.currentUserId == p.author.id ||
                    (widget.currentUserRole?.toLowerCase().replaceAll(
                          RegExp(r'[^a-z]'),
                          '',
                        ) ==
                        'admin')) ...[
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? errorColor : appBlack,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Material(
      color: active ? color.withOpacity(0.08) : appGreyVeryLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? color.withOpacity(0.2)
                  : appGreyLight.withOpacity(0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
