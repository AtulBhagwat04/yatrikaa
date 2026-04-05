const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/', (req, res, next) => notificationController.getNotifications(req, res, next));
router.put('/mark-all-read', (req, res, next) => notificationController.markAllAsRead(req, res, next));
router.put('/:id/read', (req, res, next) => notificationController.markAsRead(req, res, next));
router.delete('/clear-all', (req, res, next) => notificationController.clearAll(req, res, next));

module.exports = router;
