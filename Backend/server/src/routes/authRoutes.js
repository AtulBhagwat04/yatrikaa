const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.post('/register', (req, res, next) => authController.register(req, res, next));
router.post('/login', (req, res, next) => authController.login(req, res, next));

const upload = require('../middleware/uploadMiddleware');

// Protected routes
router.put('/profile', protect, upload.single('profilePicture'), (req, res, next) => authController.updateProfile(req, res, next));
router.put('/change-password', protect, (req, res, next) => authController.changePassword(req, res, next));

// Guide requests logic
router.post('/request-guide', protect, (req, res, next) => authController.requestGuideRole(req, res, next));

// Admin only routes
router.get('/users', protect, authorize('admin'), (req, res, next) => authController.getAllUsers(req, res, next));
router.delete('/users/:id', protect, authorize('admin'), (req, res, next) => authController.deleteUser(req, res, next));
router.get('/guide-requests', protect, authorize('admin'), (req, res, next) => authController.getGuideRequests(req, res, next));
router.post('/guide-requests/handle', protect, authorize('admin'), (req, res, next) => authController.handleGuideRequest(req, res, next));

module.exports = router;
