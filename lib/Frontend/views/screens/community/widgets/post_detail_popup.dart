import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhatkanti_app/Frontend/core/models/post_model.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';

class PostDetailPopUp extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final Function(BuildContext) onComment;

  const PostDetailPopUp({
    super.key,
    required this.post,
    required this.currentUserId,
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
    _isLiked =
        widget.currentUserId != null &&
        widget.post.likes.contains(widget.currentUserId);
    _likeCount = widget.post.likes.length;
  }

  @override
  void didUpdateWidget(PostDetailPopUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.likes != widget.post.likes ||
        oldWidget.post.comments.length != widget.post.comments.length) {
      setState(() {
        _isLiked =
            widget.currentUserId != null &&
            widget.post.likes.contains(widget.currentUserId);
        _likeCount = widget.post.likes.length;
      });
    }
  }

  void _localLike() {
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.post.imageUrl,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 15,
                      right: 15,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.post.location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          child: Text(
                            widget.post.author.name.isNotEmpty
                                ? widget.post.author.name[0]
                                : '?',
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.body(
                              widget.post.author.name,
                              fontWeight: FontWeight.bold,
                              size: 15,
                            ),
                            AppText.caption(AppStrings.commTraveler, size: 12),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppText.body(
                      widget.post.caption,
                      size: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DetailAction(
                          icon: _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: '$_likeCount',
                          color: _isLiked ? Colors.redAccent : Colors.grey,
                          onTap: _localLike,
                        ),
                        _DetailAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '${widget.post.comments.length}',
                          color: Colors.grey,
                          onTap: () => widget.onComment(context),
                        ),
                        _DetailAction(
                          icon: Icons.share_rounded,
                          label: AppStrings.commShare,
                          color: Colors.grey,
                          onTap: widget.onShare,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
    );
  }
}
