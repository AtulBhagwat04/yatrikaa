import 'package:flutter/material.dart';
import 'package:bhatkanti_app/Frontend/core/models/post_model.dart';
import 'package:bhatkanti_app/Frontend/core/services/post_service.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_colors.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_strings.dart';
import 'package:bhatkanti_app/Frontend/core/constants/app_text.dart';
import 'package:bhatkanti_app/Frontend/core/constants/spacing.dart';

class CommentsSheet extends StatefulWidget {
  final PostModel post;
  final Function(PostModel) onUpdate;
  final String? currentUserId;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.onUpdate,
    this.currentUserId,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;
  late PostModel _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    final updatedPost = await PostService().commentOnPost(
      _currentPost.id,
      _commentController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (updatedPost != null) {
        setState(() {
          _currentPost = updatedPost;
          _commentController.clear();
        });
        widget.onUpdate(updatedPost);
      }
    }
  }

  void _deleteComment(String commentId) async {
    final updatedPost = await PostService().deleteComment(
      _currentPost.id,
      commentId,
    );

    if (mounted && updatedPost != null) {
      setState(() {
        _currentPost = updatedPost;
      });
      widget.onUpdate(updatedPost);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.commCommentDeleted)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          AppText.heading(AppStrings.commComments, size: 18),
          const Divider(),
          Expanded(
            child: _currentPost.comments.isEmpty
                ? Center(child: AppText.caption(AppStrings.commNoComments))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.ms),
                    itemCount: _currentPost.comments.length,
                    itemBuilder: (context, index) {
                      final comment = _currentPost.comments[index];
                      final isCommentOwner =
                          widget.currentUserId == comment.user.id;
                      final isPostOwner =
                          widget.currentUserId == widget.post.author.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryBlue.withOpacity(0.1),
                              child: Text(
                                comment.user.name.isNotEmpty
                                    ? comment.user.name[0]
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.body(
                                    comment.user.name,
                                    fontWeight: FontWeight.bold,
                                    size: 12,
                                  ),
                                  const SizedBox(height: 2),
                                  AppText.body(
                                    comment.text,
                                    size: 12,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                            if (isCommentOwner || isPostOwner)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _deleteComment(comment.id),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.commAddComment,
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isSending ? null : _submitComment,
                  child: _isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          AppStrings.commPost,
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
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
}
