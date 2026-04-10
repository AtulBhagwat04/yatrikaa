const mongoose = require('mongoose');

const placeSchema = new mongoose.Schema({
  place_id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  formatted_address: String,
  vicinity: String,
  geometry: {
    location: {
      lat: Number,
      lng: Number
    }
  },
  photos: [{
    photo_reference: String,
    width: Number,
    height: Number
  }],
  images: [String],
  rating: Number,
  user_ratings_total: Number,
  types: [String],
  editorial_summary: {
    overview: String
  },
  opening_hours: {
    open_now: Boolean,
    weekday_text: [String]
  },
  website: String,
  reviews: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    author_name: String,
    profile_photo_url: String,
    rating: Number,
    text: String,
    relative_time_description: String,
    time: Number
  }],
  entry_fee: String,
  best_time: String,
  difficulty: String,
  parking_available: Boolean,
  suitable_for: String,
  photography_allowed: Boolean,
  facilities: [String]
}, { 
  timestamps: true,
  collection: 'places'
});

placeSchema.index({ "geometry.location": "2dsphere" });
placeSchema.index({ rating: -1, user_ratings_total: -1 });

const Place = mongoose.model('Place', placeSchema);

module.exports = Place;
