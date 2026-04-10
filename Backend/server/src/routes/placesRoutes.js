const express = require('express');
const router = express.Router();
const placesController = require('../controllers/placesController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

// Public routes
router.get('/popular', (req, res, next) => placesController.getPopularPlaces(req, res, next));
router.get('/search', (req, res, next) => placesController.searchPlaces(req, res, next));
router.get('/nearby', (req, res, next) => placesController.getNearbyPlaces(req, res, next));
router.get('/details/:placeId', (req, res, next) => placesController.getPlaceDetails(req, res, next));
router.get('/photo/:photoReference', (req, res, next) => placesController.getPhoto(req, res, next));

// Admin only routes
router.post('/', protect, authorize('admin'), upload.array('images', 10), (req, res, next) => placesController.addPlace(req, res, next));
router.put('/:id', protect, authorize('admin'), upload.array('images', 10), (req, res, next) => placesController.editPlace(req, res, next));
router.delete('/:id', protect, authorize('admin'), (req, res, next) => placesController.deletePlace(req, res, next));

// Reviews
router.post('/:id/reviews', protect, (req, res, next) => placesController.addReview(req, res, next));
router.put('/:placeId/reviews/:reviewId', protect, (req, res, next) => placesController.updateReview(req, res, next));
router.delete('/:placeId/reviews/:reviewId', protect, (req, res, next) => placesController.deleteReview(req, res, next));


// Favorites
router.get('/favorites', protect, (req, res, next) => placesController.getFavoritePlaces(req, res, next));
router.post('/toggle-favorite', protect, (req, res, next) => placesController.toggleFavorite(req, res, next));

module.exports = router;
