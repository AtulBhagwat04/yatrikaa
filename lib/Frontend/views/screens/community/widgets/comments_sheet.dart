import 'package:yatrikaa/Frontend/core/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:yatrikaa/Frontend/core/models/post_model.dart';
import 'package:yatrikaa/Frontend/core/services/post_service.dart';
import 'package:yatrikaa/Frontend/core/constants/app_colors.dart';
import 'package:yatrikaa/Frontend/core/constants/app_strings.dart';
import 'package:yatrikaa/Frontend/core/constants/app_text.dart';
import 'package:yatrikaa/Frontend/core/constants/spacing.dart';

class CommentsSheet extends StatefulWidget {
  final PostModel post;
  final Function(PostModel) onUpdate;
  final String? currentUserId;
  final String? currentUserRole;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.onUpdate,
    this.currentUserId,
    this.currentUserRole,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;
  late PostModel _currentPost;
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    PostModel? updatedPost;

    if (_editingCommentId != null) {
      updatedPost = await PostService().editComment(
        _currentPost.id,
        _editingCommentId!,
        _commentController.text.trim(),
      );
    } else {
      updatedPost = await PostService().commentOnPost(
        _currentPost.id,
        _commentController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isSending = false);
      if (updatedPost != null) {
        setState(() {
          _currentPost = updatedPost!;
          _commentController.clear();
          _editingCommentId = null;
        });
        widget.onUpdate(updatedPost);
      }
    }
  }

  void _startEditing(PostComment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.text;
    });
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
      CustomToast.success(context, AppStrings.commCommentDeleted);
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
                      final userRole = widget.currentUserRole
                          ?.toLowerCase()
                          .replaceAll(RegExp(r'[^a-z]'), '');
                      final isAdmin = userRole == 'admin';
                      final canDelete =
                          isCommentOwner || isPostOwner || isAdmin;
                      final canEdit = isCommentOwner || isAdmin;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryBlue.withValues(alpha: 0.1),
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
                            if (canEdit || canDelete)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => _startEditing(comment),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  if (canEdit && canDelete)
                                    const SizedBox(width: 8),
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () =>
                                          _deleteComment(comment.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_editingCommentId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.caption(
                          'Editing comment...',
                          color: primaryBlue,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _editingCommentId = null;
                              _commentController.clear();
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _editingCommentId != null
                              ? 'Edit your comment...'
                              : AppStrings.commAddComment,
                          border: InputBorder.none,
                          hintStyle: const TextStyle(fontSize: 14),
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
                          : Text(
                              _editingCommentId != null
                                  ? 'Update'
                                  : AppStrings.commPost,
                              style: const TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
