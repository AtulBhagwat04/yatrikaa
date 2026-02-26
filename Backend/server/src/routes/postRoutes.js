const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const { protect } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

router.post('/', protect, upload.single('image'), postController.createPost);
router.get('/', postController.getAllPosts);
router.post('/:id/like', protect, postController.likePost);
router.post('/:id/comment', protect, postController.addComment);
router.delete('/:postId/comments/:commentId', protect, postController.deleteComment);

module.exports = router;
