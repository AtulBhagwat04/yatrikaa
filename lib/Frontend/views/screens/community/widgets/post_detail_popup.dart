import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yatrikaa/Frontend/core/models/post_model.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';

class PostDetailPopUp extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final String? currentUserRole;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final Function(BuildContext) onComment;

  const PostDetailPopUp({
    super.key,
    required this.post,
    required this.currentUserId,
    this.currentUserRole,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onShare,
    required this.onComment,
  });

  @override
  State<PostDetailPopUp> createState() => _PostDetailPopUpState();
}

class _PostDetailPopUpState extends State<PostDetailPopUp> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;
  }

  @override
  void didUpdateWidget(PostDetailPopUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked ||
        oldWidget.likeCount != widget.likeCount ||
        oldWidget.post.comments.length != widget.post.comments.length) {
      setState(() {
        _isLiked = widget.isLiked;
        _likeCount = widget.likeCount;
      });
    }
  }

  void _localLike() {
    // Add quick haptic feedback for better feel
    HapticFeedback.lightImpact();
    setState(() {
      if (_isLiked) {
        _likeCount--;
      } else {
        _likeCount++;
      }
      _isLiked = !_isLiked;
    });
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.post.primaryImageUrl,
                        width: double.infinity,
                        height: 320,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: appGreyVeryLight, height: 320),
                        errorWidget: (context, url, error) => Container(
                          color: appGreyVeryLight,
                          height: 320,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_not_supported_outlined,
                                color: appGrey,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                ),
                                child: Text(
                                  "Image not available",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: appGrey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                              stops: const [0, 0.2, 0.7, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 15,
                        right: 15,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black26,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 15,
                        left: 15,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              color: Colors.black26,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: appWhite,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.post.location,
                                    style: const TextStyle(
                                      color: appWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryBlue.withOpacity(0.1),
                              child: Text(
                                widget.post.author.name.isNotEmpty
                                    ? widget.post.author.name[0]
                                    : '?',
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.body(
                                  widget.post.author.name,
                                  fontWeight: FontWeight.w800,
                                  size: 14,
                                ),
                                AppText.caption(
                                  AppStrings.commTraveler,
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppText.body(
                        widget.post.caption,
                        size: 13,
                        color: appBlack.withOpacity(0.8),
                        height: 1.4,
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appGreyVeryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: appGreyLight.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _DetailAction(
                              icon: _isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: '$_likeCount',
                              color: _isLiked ? Colors.redAccent : appGrey,
                              onTap: _localLike,
                            ),
                            _DetailAction(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: '${widget.post.comments.length}',
                              color: appGrey,
                              onTap: () => widget.onComment(context),
                            ),
                            _DetailAction(
                              icon: Icons.share_rounded,
                              label: AppStrings.commShare,
                              color: appGrey,
                              onTap: widget.onShare,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DetailAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
