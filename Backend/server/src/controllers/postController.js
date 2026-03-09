const Post = require('../models/Post');
const User = require('../models/User');
const { uploadImage, deleteImage } = require('../services/cloudinaryService');

class PostController {
  async createPost(req, res, next) {
    const { location, imageUrl, caption } = req.body;
    try {
      let finalImageUrl = imageUrl;

      if (req.file) {
        const folderName = `Bhatkanti/Posts/${req.user._id}`;
        const result = await uploadImage(req.file, folderName);
        finalImageUrl = result.secure_url;
      }

      const post = await Post.create({
        author: req.user._id,
        location,
        imageUrl: finalImageUrl,
        caption
      });

      // Increment user postsCount
      await User.findByIdAndUpdate(req.user._id, { $inc: { postsCount: 1 } });

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

      const isAdmin = req.user.role === 'admin' || req.user.role === 'super-admin';
      // Only allowing owner of comment or owner of post to delete, or admin
      if (!isAdmin && comment.user.toString() !== req.user._id.toString() && post.author.toString() !== req.user._id.toString()) {
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

  async editComment(req, res, next) {
    const { text } = req.body;
    try {
      const { postId, commentId } = req.params;
      const post = await Post.findById(postId);
      if (!post) return res.status(404).json({ error: 'Post not found' });

      const comment = post.comments.id(commentId);
      if (!comment) return res.status(404).json({ error: 'Comment not found' });

      const isAdmin = req.user.role === 'admin' || req.user.role === 'super-admin';
      // Only author of comment or admin can edit
      if (!isAdmin && comment.user.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Unauthorized to edit this comment' });
      }

      if (text) {
        comment.text = text;
        await post.save();
      }

      const populatedPost = await Post.findById(postId)
        .populate('author', 'name')
        .populate('comments.user', 'name');
      res.json(populatedPost);
    } catch (error) {
      next(error);
    }
  }

  async deletePost(req, res, next) {
    try {
      const post = await Post.findById(req.params.id);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      const isAdmin = req.user.role === 'admin' || req.user.role === 'super-admin';
      // Check if user is the author or admin
      if (!isAdmin && post.author.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Unauthorized to delete this post' });
      }

      // Extract publicId from imageUrl if it's a Cloudinary URL
      // Example: https://res.cloudinary.com/cloud_name/image/upload/v1/Bhatkanti/Posts/userId/filename.jpg
      if (post.imageUrl && post.imageUrl.includes('cloudinary.com')) {
        try {
          const urlParts = post.imageUrl.split('/');
          const uploadIndex = urlParts.indexOf('upload');
          if (uploadIndex !== -1) {
            // Get everything after the version (v1234567)
            const publicIdWithExt = urlParts.slice(uploadIndex + 2).join('/');
            const publicId = publicIdWithExt.split('.')[0];
            await deleteImage(publicId);
          }
        } catch (cloudinaryError) {
          console.error('Error deleting image from Cloudinary:', cloudinaryError.message);
        }
      }

      await Post.findByIdAndDelete(req.params.id);

      // Decrement user postsCount
      await User.findByIdAndUpdate(post.author, { $inc: { postsCount: -1 } });

      res.json({ message: 'Post deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  async updatePost(req, res, next) {
    const { location, caption } = req.body;
    try {
      let post = await Post.findById(req.params.id);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      const isAdmin = req.user.role === 'admin' || req.user.role === 'super-admin';
      if (!isAdmin && post.author.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Unauthorized to edit this post' });
      }

      post.location = location || post.location;
      post.caption = caption || post.caption;

      if (req.file) {
        // Delete old image if exists
        if (post.imageUrl && post.imageUrl.includes('cloudinary.com')) {
          try {
            const urlParts = post.imageUrl.split('/');
            const uploadIndex = urlParts.indexOf('upload');
            if (uploadIndex !== -1) {
              const publicIdWithExt = urlParts.slice(uploadIndex + 2).join('/');
              const publicId = publicIdWithExt.split('.')[0];
              await deleteImage(publicId);
            }
          } catch (e) {
            console.error('Error deleting old image:', e.message);
          }
        }

        const folderName = `Bhatkanti/Posts/${req.user._id}`;
        const result = await uploadImage(req.file, folderName);
        post.imageUrl = result.secure_url;
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
}

module.exports = new PostController();
