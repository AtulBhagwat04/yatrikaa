const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.post('/register', (req, res, next) => authController.register(req, res, next));
router.post('/login', (req, res, next) => authController.login(req, res, next));

// Protected routes
router.put('/profile', protect, (req, res, next) => authController.updateProfile(req, res, next));
router.put('/change-password', protect, (req, res, next) => authController.changePassword(req, res, next));

// SuperAdmin only routes
router.get('/users', protect, authorize('super-admin'), (req, res, next) => authController.getAllUsers(req, res, next));
router.delete('/users/:id', protect, authorize('super-admin'), (req, res, next) => authController.deleteUser(req, res, next));

module.exports = router;
