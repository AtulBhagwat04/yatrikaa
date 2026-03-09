const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const { protect } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

router.post('/', protect, upload.single('image'), postController.createPost);
router.get('/', postController.getAllPosts);
router.post('/:id/like', protect, postController.likePost);
router.post('/:id/comment', protect, postController.addComment);
router.put('/:postId/comments/:commentId', protect, postController.editComment);
router.delete('/:postId/comments/:commentId', protect, postController.deleteComment);
router.delete('/:id', protect, postController.deletePost);
router.put('/:id', protect, upload.single('image'), postController.updatePost);

module.exports = router;
