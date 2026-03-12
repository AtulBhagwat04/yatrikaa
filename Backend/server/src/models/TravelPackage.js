const mongoose = require('mongoose');

const travelPackageSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    required: true,
  },
  images: [{
    type: String,
  }],
  destination: {
    name: { type: String, required: true },
    location: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
    },
  },
  duration: {
    days: { type: Number, default: 1 },
    nights: { type: Number, default: 0 },
  },
  price: {
    type: Number,
    required: true,
  },
  maxGroupSize: {
    type: Number,
    required: true,
  },
  currentParticipants: {
    type: Number,
    default: 0,
  },
  difficulty: {
    type: String,
    enum: ['Easy', 'Moderate', 'Hard', 'Very Hard', 'Expert'],
    default: 'Moderate',
  },
  category: {
    type: String,
    enum: ['Adventure', 'Fort Trek', 'Spiritual', 'Beach', 'Road Trip', 'Weekend Trip', 'Wildlife', 'Cultural'],
    required: true,
  },
  itinerary: [{
    day: { type: Number, required: true },
    title: { type: String, required: true },
    activities: [{ type: String }],
  }],
  inclusions: [{
    type: String,
  }],
  exclusions: [{
    type: String,
  }],
  bestSeason: {
    type: String,
  },
  organizer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['Draft', 'Published', 'Completed', 'Cancelled'],
    default: 'Published',
  },
  isPopular: {
    type: Boolean,
    default: false,
  },
  ratings: {
    average: { type: Number, default: 0 },
    count: { type: Number, default: 0 },
  }
}, {
  timestamps: true,
  collection: 'travel_packages',
});

const TravelPackage = mongoose.model('TravelPackage', travelPackageSchema);

module.exports = TravelPackage;
