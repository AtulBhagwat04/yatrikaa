const express = require('express');
const router = express.Router();
const placesController = require('../controllers/placesController');


 // @route GET /api/places/nearby
router.get('/nearby', placesController.getNearby);

 //@route GET /api/places/search
router.get('/search', placesController.search);

// @route GET /api/places/details/:placeId
router.get('/details/:placeId', placesController.getDetails);


// @route GET /api/places/photo/:photoReference
router.get('/photo/:photoReference', placesController.getPhoto);

module.exports = router;
