const Post = require('../models/Post');
const { uploadImage } = require('../services/cloudinaryService');

class PostController {
  async createPost(req, res, next) {
    const { location, imageUrl, caption } = req.body;
    try {
      let finalImageUrl = imageUrl;

      if (req.file) {
        const result = await uploadImage(req.file);
        finalImageUrl = result.secure_url;
      }

      const post = await Post.create({
        author: req.user._id,
        location,
        imageUrl: finalImageUrl,
        caption
      });

      const populatedPost = await Post.findById(post._id).populate('author', 'name');

      res.status(201).json(populatedPost);
    } catch (error) {
      next(error);
    }
  }

  async getAllPosts(req, res, next) {
    try {
      const posts = await Post.find({})
        .populate('author', 'name')
        .populate('comments.user', 'name')
        .sort({ createdAt: -1 });
      res.json(posts);
    } catch (error) {
      next(error);
    }
  }

  async likePost(req, res, next) {
    try {
      const post = await Post.findById(req.params.id);
      if (!post) return res.status(404).json({ error: 'Post not found' });

      // Correct comparison for Mongoose Object IDs
      const userId = req.user._id.toString();
      const likedIndex = post.likes.findIndex(id => id.toString() === userId);

      if (likedIndex === -1) {
        post.likes.push(req.user._id);
      } else {
        post.likes.splice(likedIndex, 1);
      }

      await post.save();
      const populatedPost = await Post.findById(post._id)
        .populate('author', 'name')
        .populate('comments.user', 'name');
      res.json(populatedPost);
    } catch (error) {
      next(error);
    }
  }

  async addComment(req, res, next) {
    const { text } = req.body;
    try {
      const post = await Post.findById(req.params.id);
      if (!post) return res.status(404).json({ error: 'Post not found' });

      post.comments.push({
        user: req.user._id,
        text
      });

      await post.save();
      const populatedPost = await Post.findById(post._id)
        .populate('author', 'name')
        .populate('comments.user', 'name');
      res.json(populatedPost);
    } catch (error) {
      next(error);
    }
  }

  async deleteComment(req, res, next) {
    try {
      const { postId, commentId } = req.params;
      const post = await Post.findById(postId);
      if (!post) return res.status(404).json({ error: 'Post not found' });

      const comment = post.comments.id(commentId);
      if (!comment) return res.status(404).json({ error: 'Comment not found' });

      // Only allowing owner of comment or owner of post to delete
      if (comment.user.toString() !== req.user._id.toString() && post.author.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Unauthorized to delete this comment' });
      }

      post.comments.pull(commentId);
      await post.save();
      
      const populatedPost = await Post.findById(postId)
        .populate('author', 'name')
        .populate('comments.user', 'name');
      res.json(populatedPost);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PostController();
