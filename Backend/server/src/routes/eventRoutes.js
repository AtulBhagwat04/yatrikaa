const express = require('express');
const router = express.Router();
const eventsController = require('../controllers/eventsController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

// Public routes
router.get('/', (req, res, next) => eventsController.getEvents(req, res, next));
router.get('/:id', (req, res, next) => eventsController.getEventDetails(req, res, next));

// Admin only routes
router.post('/', protect, authorize('admin', 'super-admin'), upload.array('images', 3), (req, res, next) => eventsController.addEvent(req, res, next));
router.put('/:id', protect, authorize('admin', 'super-admin'), upload.array('images', 3), (req, res, next) => eventsController.editEvent(req, res, next));
router.delete('/:id', protect, authorize('admin', 'super-admin'), (req, res, next) => eventsController.deleteEvent(req, res, next));
router.post('/:id/interest', protect, (req, res, next) => eventsController.toggleInterest(req, res, next));

module.exports = router;
