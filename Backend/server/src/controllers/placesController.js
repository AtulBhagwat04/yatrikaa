const Place = require('../models/Place');
const User = require('../models/User');
const googlePlacesService = require('../services/placesService');
const wikipediaService = require('../services/wikipediaService');
const notificationService = require('../services/notificationService');
const { uploadImage } = require('../services/cloudinaryService');

class PlacesController {
  /**
   * Get popular places from MongoDB with optional pagination
   * Query params: category, page (default 1), limit (default 12, 0 = all)
   */
  async getPopularPlaces(req, res, next) {
    const { category, query } = req.query;
    const activeCategory = category || query; // Handle both param names
    const page  = Math.max(1, parseInt(req.query.page  || '1',  10));
    const limit = Math.max(0, parseInt(req.query.limit || '12', 10));

    try {
      let filter = {};
      if (activeCategory && activeCategory !== 'All') {
        filter = {
          $or: [
            { types: { $regex: activeCategory, $options: 'i' } },
            { name: { $regex: activeCategory, $options: 'i' } },
            { formatted_address: { $regex: activeCategory, $options: 'i' } },
            { category: { $regex: activeCategory, $options: 'i' } }
          ]
        };
      }

      const baseQuery = Place.find(filter).sort({ rating: -1, user_ratings_total: -1 });

      let places;
      let totalCount;

      if (limit === 0) {
        places     = await baseQuery;
        totalCount = places.length;
      } else {
        totalCount = await Place.countDocuments(filter);
        places     = await baseQuery.skip((page - 1) * limit).limit(limit)
          .populate('reviews.user', 'name profilePicture');
      }

      let results = [...places];

      // If DB results are low for a specific category, no external supplementing for category
      // (Wikipedia GeoSearch is location-based, not category-based)

      const totalPages = limit > 0 ? Math.ceil(totalCount / limit) : 1;
      const hasMore    = limit > 0 && page < totalPages;

      res.status(200).json({
        status: "OK",
        count: results.length,
        totalCount: Math.max(totalCount, results.length),
        page,
        totalPages,
        hasMore,
        results: results,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetch nearby places, prioritizing DB then falling back to Google
   */
  async getNearbyPlaces(req, res, next) {
    const { lat, lng, radius = 10000 } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ error: "Missing lat/lng" });
    }

    try {
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      const rad = parseInt(radius);

      // 1. Search DB — only fetch places that have at least one stored image
      let dbPlaces = [];
      try {
        dbPlaces = await Place.find({
          "geometry.location": {
            $nearSphere: {
              $geometry: {
                type: "Point",
                coordinates: [longitude, latitude],
              },
              $maxDistance: rad,
            },
          },
          // ✅ Only DB places that have a real stored image
          $or: [
            { "photos.0.photo_reference": { $exists: true, $ne: "" } },
            { "images.0": { $exists: true, $ne: "" } },
          ],
        }).limit(10);
      } catch (dbErr) {
        console.error("Geo Search Error (Check if Index exists):", dbErr.message);
        // Fallback to simple find if index missing
      }

      // 2. Supplement with Wikipedia (free, no API key required)
      let results = [...dbPlaces];
      console.log(`[Nearby] Initial DB found ${dbPlaces.length} places.`);

      if (results.length < 5) {
        try {
          console.log('[Nearby] Supplementing with Wikipedia GeoSearch...');
          const wikiResult = await wikipediaService.getNearbyPlaces(latitude, longitude, rad);
          if (wikiResult && wikiResult.results) {
            const currentIds = new Set(results.map(p => p.place_id));
            const uniqueWiki = wikiResult.results.filter(p => !currentIds.has(p.place_id));
            console.log(`[Nearby] Wikipedia found ${uniqueWiki.length} unique results.`);
            results = [...results, ...uniqueWiki];
          }
        } catch (wikiErr) {
          console.error('[Nearby] Wikipedia fallback error:', wikiErr.message);
        }
      }

      // ✅ Filter out places with no images before sending to frontend
      const hasImage = (p) => {
        const photos = p.photos || p.images || [];
        if (photos.length === 0) return false;
        const ref = photos[0]?.photo_reference || photos[0];
        return ref && typeof ref === 'string' && ref.startsWith('http');
      };
      const withImages = results.filter(hasImage);

      console.log(`[Nearby] Final: ${withImages.length} places with images (of ${results.length} total)`);
      if (withImages.length > 0) {
        console.log(`[Nearby] Sample: ${withImages[0].name} (from ${withImages[0].source || 'DB'})`);
      }
      res.status(200).json({
        status: "OK",
        results: withImages
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
      const dbPlace = await Place.findOne({ place_id: placeId })
        .populate('reviews.user', 'name profilePicture');
      if (dbPlace) {
        return res.status(200).json({
          status: "OK",
          result: dbPlace
        });
      }

      // 2. Fallback to Google if not in DB
      console.log(`[PlaceDetails] Not in DB, falling back to Google for: ${placeId}`);

      // 3. Last fallback to Google
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
      if (typeof body.editorial_summary === 'string') {
        try { body.editorial_summary = JSON.parse(body.editorial_summary); } catch (e) {}
      }
      if (typeof body.rating === 'string') body.rating = parseFloat(body.rating);
      if (typeof body.user_ratings_total === 'string') body.user_ratings_total = parseInt(body.user_ratings_total);
      if (body.parking_available === 'true') body.parking_available = true;
      if (body.parking_available === 'false') body.parking_available = false;
      if (body.photography_allowed === 'true') body.photography_allowed = true;
      if (body.photography_allowed === 'false') body.photography_allowed = false;

      // If files are uploaded, upload each to Cloudinary and set as photos
      if (req.files && req.files.length > 0) {
        const folderName = `Yatrikaa/Places/${(body.name || 'unnamed').replace(/\s+/g, '_')}`;
        const uploadPromises = req.files.map(file => uploadImage(file, folderName));
        const results = await Promise.all(uploadPromises);
        
        body.photos = results.map(result => ({
          photo_reference: result.secure_url,
          width: result.width,
          height: result.height
        }));
        body.images = results.map(result => result.secure_url);
      }

      const place = await Place.create(body);

      // --- BROADCAST NOTIFICATION ---
      // Notify all users about the new destination
      notificationService.sendToTopic('all_users', {
        title: 'New Destination Alert! 🏰',
        body: `"${place.name}" is now available in Yatrikaa. Start planning your visit!`,
      }, { type: 'new_place', placeId: place.place_id }).catch(e => console.error(e));

      res.status(201).json({ status: "OK", result: place });
    } catch (error) {
      next(error);
    }
  }

  async editPlace(req, res, next) {
    try {
      let body = { ...req.body };

      // Multi-part form-data sends everything as strings. Parse nested JSON.
      const jsonFields = ['geometry', 'opening_hours', 'facilities', 'types', 'photos', 'images', 'editorial_summary'];
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
      
      // Ensure photos are objects if they came as strings (from older frontend versions or simplified updates)
      if (Array.isArray(body.photos)) {
        body.photos = body.photos.map(p => typeof p === 'string' ? { photo_reference: p } : p);
      }
      
      if (typeof body.rating === 'string') body.rating = parseFloat(body.rating);
      if (typeof body.user_ratings_total === 'string') body.user_ratings_total = parseInt(body.user_ratings_total);
      if (body.parking_available === 'true') body.parking_available = true;
      if (body.parking_available === 'false') body.parking_available = false;
      if (body.photography_allowed === 'true') body.photography_allowed = true;
      if (body.photography_allowed === 'false') body.photography_allowed = false;

      // If files are uploaded, upload each to Cloudinary and append to photos/images
      if (req.files && req.files.length > 0) {
        const folderName = `Yatrikaa/Places/${(body.name || 'unnamed').replace(/\s+/g, '_')}`;
        const uploadPromises = req.files.map(file => uploadImage(file, folderName));
        const results = await Promise.all(uploadPromises);
        
        const newPhotos = results.map(result => ({
          photo_reference: result.secure_url,
          width: result.width,
          height: result.height
        }));
        const newImages = results.map(result => result.secure_url);
        
        body.photos = Array.isArray(body.photos) ? [...body.photos, ...newPhotos] : newPhotos;
        body.images = Array.isArray(body.images) ? [...body.images, ...newImages] : newImages;
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
    const { placeId, reviewId } = req.params;
    try {
      let place = await Place.findOne({ place_id: placeId });
      
      // FALLBACK: If not found in the suggested place, search globally in all places
      if (!place || !place.reviews.id(reviewId)) {
        place = await Place.findOne({ "reviews._id": reviewId });
      }

      if (!place) {
        console.log(`[deleteReview] Review ${reviewId} not found globally in any place`);
        return res.status(404).json({ error: "Review not found" });
      }

      const review = place.reviews.id(reviewId);
      if (!review) {
        console.log(`[deleteReview] Review ${reviewId} not found in place ${placeId}`);
        console.log(`[deleteReview] Available reviews in this place:`);
        place.reviews.forEach(r => {
          console.log(`  - ID: ${r._id}, Author: ${r.author_name}, Text: ${r.text}`);
        });
        return res.status(404).json({ error: "Review not found" });
      }

      // 3. Verify Ownership (Must be owner OR admin)
      const isOwner = review.user && review.user.toString() === req.user._id.toString();
      const isAdmin = req.user.role === 'admin';
      
      console.log(`[deleteReview] ReviewUser: ${review.user}, ReqUser: ${req.user._id}, isOwner: ${isOwner}, isAdmin: ${isAdmin}`);

      if (!isOwner && !isAdmin) {
        return res.status(403).json({ error: "Unauthorized to delete this review" });
      }

      const reviewRating = review.rating;
      
      // Use .pull() for robust removal
      place.reviews.pull(reviewId);

      // 4. Recalculate ratings
      const newCount = place.reviews.length;
      if (newCount > 0) {
        const totalRatingValue = (place.rating * (newCount + 1)) - reviewRating;
        place.rating = parseFloat((totalRatingValue / newCount).toFixed(1));
        place.user_ratings_total = newCount;
      } else {
        place.rating = 0;
        place.user_ratings_total = 0;
      }

      await place.save();

      // Update User review count
      await User.findByIdAndUpdate(req.user._id, { $inc: { reviewsCount: -1 } });

      res.status(200).json({ status: "OK", message: "Review deleted successfully", result: place });
    } catch (error) {
      next(error);
    }
  }

  async updateReview(req, res, next) {
    const { placeId, reviewId } = req.params;
    const { rating, text } = req.body;

    try {
      const place = await Place.findOne({ place_id: placeId });
      if (!place) return res.status(404).json({ error: "Place not found" });

      const review = place.reviews.id(reviewId);
      if (!review) return res.status(404).json({ error: "Review not found" });

      if (review.user.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: "Unauthorized to update this review" });
      }

      const oldRating = review.rating;
      review.rating = parseFloat(rating);
      review.text = text;
      review.time = Math.floor(Date.now() / 1000);
      review.relative_time_description = "Edited just now";

      // Re-calculate average rating
      const totalRatingValue = (place.rating * place.user_ratings_total) - oldRating + parseFloat(rating);
      place.rating = parseFloat((totalRatingValue / place.user_ratings_total).toFixed(1));

      await place.save();
      res.status(200).json({ status: "OK", result: place });
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

  async addReview(req, res, next) {
    const { id } = req.params;
    const { rating, text } = req.body;
    const userId = req.user._id;
    const authorName = req.user.name;
    const profilePhotoUrl = req.user.profilePicture;

    try {
      if (!text || text.trim().length < 2) {
        return res.status(400).json({ error: "Review text is required and must be at least 2 characters long" });
      }
      if (!rating || rating < 1 || rating > 5) {
        return res.status(400).json({ error: "A valid rating between 1 and 5 is required" });
      }

      const place = await Place.findOne({ place_id: id });
      if (!place) return res.status(404).json({ error: "Place not found" });

      const newReview = {
        user: userId,
        author_name: authorName,
        profile_photo_url: profilePhotoUrl,
        rating: parseFloat(rating),
        text: text,
        relative_time_description: "Just now",
        time: Math.floor(Date.now() / 1000)
      };

      // Update ratings
      const currentRating = place.rating || 0;
      const currentCount = place.user_ratings_total || 0;
      const newCount = currentCount + 1;
      const newRating = (currentRating * currentCount + parseFloat(rating)) / newCount;

      if (!place.reviews) place.reviews = [];
      place.reviews.push(newReview);
      place.rating = parseFloat(newRating.toFixed(1));
      place.user_ratings_total = newCount;

      await place.save();

      // Update User review count
      await User.findByIdAndUpdate(req.user._id, { $inc: { reviewsCount: 1 } });

      res.status(201).json({ status: "OK", result: place });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PlacesController();

