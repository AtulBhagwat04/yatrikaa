const Place = require('../models/Place');
const User = require('../models/User');
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
   * Fetch nearby places, prioritizing DB then falling back to Google
   */
  async getNearbyPlaces(req, res, next) {
    const { lat, lng, radius = 5000 } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ error: "Missing lat/lng" });
    }

    try {
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      const rad = parseInt(radius);

      // 1. Search DB using $near sphere (2D sphere index needed)
      let dbPlaces = [];
      try {
        dbPlaces = await Place.find({
          "geometry.location": {
            $nearSphere: {
              $geometry: {
                type: "Point",
                coordinates: [longitude, latitude] // MongoDB uses [lng, lat]
              },
              $maxDistance: rad
            }
          }
        }).limit(10);
      } catch (dbErr) {
        console.error("Geo Search Error (Check if Index exists):", dbErr.message);
        // Fallback to simple find if index missing
      }

      // 2. Supplement with Google
      let results = [...dbPlaces];
      if (dbPlaces.length < 5) {
        try {
          const googleResult = await googlePlacesService.getNearbyPlaces(latitude, longitude, rad);
          if (googleResult && googleResult.results) {
            const dbIds = new Set(dbPlaces.map(p => p.place_id));
            const uniqueGoogle = googleResult.results.filter(p => !dbIds.has(p.place_id));
            results = [...dbPlaces, ...uniqueGoogle];
          }
        } catch (gErr) {
          console.error("Google Nearby Error:", gErr.message);
        }
      }

      res.status(200).json({
        status: "OK",
        results: results
      });
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

      // 2. Fetch Google results if DB results are few
      let results = [...dbPlaces];
      if (dbPlaces.length < 5) {
        try {
          const googleResult = await googlePlacesService.searchPlaces(query, lat, lng);
          if (googleResult && googleResult.results) {
            // Filter out duplicates (if any) and combine
            const dbPlaceIds = new Set(dbPlaces.map(p => p.place_id));
            const uniqueGooglePlaces = googleResult.results.filter(
              p => !dbPlaceIds.has(p.place_id)
            );
            results = [...dbPlaces, ...uniqueGooglePlaces];
          }
        } catch (error) {
          console.error("Google Search Error:", error);
          // If Google fails, we still return whatever we found in DB
        }
      }

      res.status(200).json({
        status: "OK",
        results: results
      });
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

    // If photoReference is already a full URL (e.g. Cloudinary), redirect directly
    if (photoReference.startsWith('http')) {
      return res.redirect(photoReference);
    }

    // Just redirect to Google Photos URL
    const url = googlePlacesService.getPhotoUrl(photoReference, maxwidth);
    res.redirect(url);
  }

  // Admin CRUD Operations
  async addPlace(req, res, next) {
    try {
      const { uploadImage } = require('../services/cloudinaryService');
      let body = { ...req.body };
      
      // Multi-part form-data sends everything as strings. Parse nested JSON.
      if (typeof body.geometry === 'string') {
        try { body.geometry = JSON.parse(body.geometry); } catch (e) {}
      }
      if (typeof body.opening_hours === 'string') {
        try { body.opening_hours = JSON.parse(body.opening_hours); } catch (e) {}
      }
      if (typeof body.facilities === 'string') {
        try { body.facilities = JSON.parse(body.facilities); } catch (e) {}
      }
      if (typeof body.types === 'string') {
        try { body.types = JSON.parse(body.types); } catch (e) {}
      }
      if (typeof body.rating === 'string') body.rating = parseFloat(body.rating);
      if (typeof body.user_ratings_total === 'string') body.user_ratings_total = parseInt(body.user_ratings_total);
      if (body.parking_available === 'true') body.parking_available = true;
      if (body.parking_available === 'false') body.parking_available = false;
      if (body.photography_allowed === 'true') body.photography_allowed = true;
      if (body.photography_allowed === 'false') body.photography_allowed = false;

      // If a file is uploaded, upload to Cloudinary and set as photo
      if (req.file) {
        const folderName = `Bhatkanti/Places/${(body.name || 'unnamed').replace(/\s+/g, '_')}`;
        const result = await uploadImage(req.file, folderName);
        body.photos = [{
          photo_reference: result.secure_url,
          width: result.width,
          height: result.height
        }];
      }

      const place = await Place.create(body);
      res.status(201).json({ status: "OK", result: place });
    } catch (error) {
      next(error);
    }
  }

  async editPlace(req, res, next) {
    try {
      const { uploadImage } = require('../services/cloudinaryService');
      let body = { ...req.body };

      // Multi-part form-data sends everything as strings. Parse nested JSON.
      const jsonFields = ['geometry', 'opening_hours', 'facilities', 'types', 'photos', 'images'];
      jsonFields.forEach(field => {
        if (typeof body[field] === 'string' && body[field].trim() !== '') {
          try {
            body[field] = JSON.parse(body[field]);
          } catch (e) {
            console.warn(`Failed to parse ${field} JSON`);
            // If it's supposed to be an array but parsing failed, initialize as empty array
            if (['photos', 'images', 'facilities', 'types'].includes(field)) {
              body[field] = [];
            }
          }
        }
      });
      
      if (typeof body.rating === 'string') body.rating = parseFloat(body.rating);
      if (typeof body.user_ratings_total === 'string') body.user_ratings_total = parseInt(body.user_ratings_total);
      if (body.parking_available === 'true') body.parking_available = true;
      if (body.parking_available === 'false') body.parking_available = false;
      if (body.photography_allowed === 'true') body.photography_allowed = true;
      if (body.photography_allowed === 'false') body.photography_allowed = false;

      // If a file is uploaded, upload to Cloudinary and append to photos/images
      if (req.file) {
        const folderName = `Bhatkanti/Places/${(body.name || 'unnamed').replace(/\s+/g, '_')}`;
        const result = await uploadImage(req.file, folderName);
        const newPhoto = {
          photo_reference: result.secure_url,
          width: result.width,
          height: result.height
        };
        
        body.photos = Array.isArray(body.photos) ? [...body.photos, newPhoto] : [newPhoto];
        body.images = Array.isArray(body.images) ? [...body.images, result.secure_url] : [result.secure_url];
      }

      const place = await Place.findOneAndUpdate({ place_id: req.params.id }, body, { new: true });
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

  async getFavoritePlaces(req, res, next) {
    try {
      const user = await User.findById(req.user._id);
      if (!user) return res.status(404).json({ error: "User not found" });

      let favoriteIds = user.favoritePlaces || [];
      favoriteIds = favoriteIds.map(id => id.trim()).filter(id => id !== "");
      
      let places = await Place.find({ place_id: { $in: favoriteIds } });

      // Handle missing places (places favorited but not in our DB)
      if (places.length < favoriteIds.length) {
        const foundIds = places.map(p => p.place_id);
        const missingIds = favoriteIds.filter(id => !foundIds.includes(id));
        for (const missingId of missingIds) {
          try {
            // Fetch from Google
            const details = await googlePlacesService.getPlaceDetails(missingId);
            if (details.status === "OK" && details.result) {
              const placeData = details.result;
              const newPlace = {
                place_id: missingId,
                name: placeData.name,
                formatted_address: placeData.formatted_address,
                geometry: placeData.geometry,
                photos: placeData.photos || [],
                rating: placeData.rating || 0,
                user_ratings_total: placeData.user_ratings_total || 0,
                types: placeData.types || []
              };
              const createdPlace = await Place.create(newPlace);
              places.push(createdPlace);
            }
          } catch (syncErr) {
            console.error(`Failed to auto-sync missing place ${missingId}:`, syncErr.message);
          }
        }
      }

      // Final sync of savedCount if mismatch still exists (e.g. invalid IDs)
      if (user.savedCount !== places.length) {
        user.savedCount = places.length;
        user.favoritePlaces = places.map(p => p.place_id);
        await user.save();
      }

      res.status(200).json({
        status: "OK",
        results: places,
        count: places.length
      });
    } catch (error) {
      console.error('Error in getFavoritePlaces:', error);
      next(error);
    }
  }

  async toggleFavorite(req, res, next) {
    let { placeId, placeData } = req.body;
    if (placeId) placeId = placeId.trim();
    
    try {
      const user = await User.findById(req.user._id);
      if (!user) return res.status(404).json({ error: "User not found" });

      if (!user.favoritePlaces) user.favoritePlaces = [];

      // Check if place exists in DB, if not and placeData is provided, create it
      if (placeData) {
        const dbPlace = await Place.findOne({ place_id: placeId });
        if (!dbPlace) {
          try {
            const newPlace = {
              place_id: placeId,
              name: placeData.name,
              formatted_address: placeData.address || placeData.formatted_address,
              geometry: placeData.geometry || {
                location: { lat: placeData.lat, lng: placeData.lng }
              },
              photos: placeData.photos || (placeData.photo_reference ? [{ photo_reference: placeData.photo_reference }] : []),
              rating: placeData.rating || 0,
              user_ratings_total: placeData.user_ratings_total || 0,
              types: placeData.types || [placeData.category]
            };
            await Place.create(newPlace);
          } catch (createErr) {
            console.warn('Place creation warning:', createErr.message);
          }
        }
      }

      const index = user.favoritePlaces.indexOf(placeId);
      let isFavorite = false;

      if (index === -1) {
        user.favoritePlaces.push(placeId);
        isFavorite = true;
      } else {
        user.favoritePlaces = user.favoritePlaces.filter(id => id !== placeId);
        isFavorite = false;
      }

      // Sync savedCount
      user.savedCount = user.favoritePlaces.length;
      
      await user.save();
      res.status(200).json({
        status: "OK",
        isFavorite,
        savedCount: user.savedCount,
        favoritePlacesCount: user.favoritePlaces.length
      });
    } catch (error) {
      console.error('Error in toggleFavorite:', error);
      next(error);
    }
  }
}

module.exports = new PlacesController();
