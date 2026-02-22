const Place = require('../models/Place');
const googlePlacesService = require('../services/placesService');

class PlacesController {
  /**
   * Get popular places from MongoDB
   */
  async getPopularPlaces(req, res, next) {
    const { category } = req.query;
    try {
      let filter = {};
      if (category && category !== 'All') {
        filter = {
          $or: [
            { types: { $regex: category, $options: 'i' } },
            { name: { $regex: category, $options: 'i' } },
            { formatted_address: { $regex: category, $options: 'i' } }
          ]
        };
      }

      const places = await Place.find(filter).sort({ rating: -1, user_ratings_total: -1 });
      
      res.status(200).json({
        status: "OK",
        results: places
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Nearby search (Fallback to Google if not in DB, or search DB first)
   */
  async getNearbyPlaces(req, res, next) {
    const { lat, lng, radius, type } = req.query;
    try {
      // For now, let's keep nearby as Google-powered or implement geo-spatial search in DB
      const result = await googlePlacesService.getNearbyPlaces(parseFloat(lat), parseFloat(lng), parseInt(radius));
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Search places (prioritize DB, fallback to Google)
   */
  async searchPlaces(req, res, next) {
    const { query, lat, lng } = req.query;
    try {
      // 1. Search in MongoDB first (regex search on name or address)
      const dbPlaces = await Place.find({
        $or: [
          { name: { $regex: query, $options: 'i' } },
          { formatted_address: { $regex: query, $options: 'i' } }
        ]
      }).limit(10);

      // If we find enough in DB, return them
      if (dbPlaces.length >= 5) {
        return res.status(200).json({
          status: "OK",
          results: dbPlaces
        });
      }

      // 2. Fallback to Google if query not well-covered in DB
      const result = await googlePlacesService.searchPlaces(query, lat, lng);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getPlaceDetails(req, res, next) {
    const { placeId } = req.params;
    try {
      // 1. Check DB first
      const dbPlace = await Place.findOne({ place_id: placeId });
      if (dbPlace) {
        return res.status(200).json({
          status: "OK",
          result: dbPlace
        });
      }

      // 2. Fallback to Google
      const result = await googlePlacesService.getPlaceDetails(placeId);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getPhoto(req, res) {
    const { photoReference } = req.params;
    const { maxwidth } = req.query;
    // Just redirect to Google Photos URL
    const url = googlePlacesService.getPhotoUrl(photoReference, maxwidth);
    res.redirect(url);
  }

  // Admin CRUD Operations
  async addPlace(req, res, next) {
    try {
      const place = await Place.create(req.body);
      res.status(201).json({ status: "OK", result: place });
    } catch (error) {
      next(error);
    }
  }

  async editPlace(req, res, next) {
    try {
      const place = await Place.findOneAndUpdate({ place_id: req.params.id }, req.body, { new: true });
      if (!place) return res.status(404).json({ error: "Place not found" });
      res.status(200).json({ status: "OK", result: place });
    } catch (error) {
      next(error);
    }
  }

  async deletePlace(req, res, next) {
    try {
      const place = await Place.findOneAndDelete({ place_id: req.params.id });
      if (!place) return res.status(404).json({ error: "Place not found" });
      res.status(200).json({ status: "OK", message: "Place deleted successfully" });
    } catch (error) {
      next(error);
    }
  }

  async deleteReview(req, res, next) {
    const { placeId, authorName, time } = req.params;
    try {
      const place = await Place.findOneAndUpdate(
        { place_id: placeId },
        { 
          $pull: { 
            reviews: { 
              author_name: authorName,
              time: parseInt(time)
            } 
          } 
        },
        { new: true }
      );

      if (!place) return res.status(404).json({ error: "Place not found" });
      res.status(200).json({ status: "OK", message: "Review deleted successfully", result: place });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PlacesController();
