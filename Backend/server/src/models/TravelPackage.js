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
    name: { type: String, required: false },
    location: {
      lat: { type: Number, required: false, default: 0 },
      lng: { type: Number, required: false, default: 0 },
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
    date: { type: Date },
    activities: [{ type: String }],
    places: [{ type: String }],
    hotelName: [{ type: String }],
    stayLocation: [{ type: String }],
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
  reviews: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    author_name: String,
    profile_photo_url: String,
    rating: Number,
    text: String,
    relative_time_description: String,
    time: Number
  }],
  ratings: {
    average: { type: Number, default: 0 },
    count: { type: Number, default: 0 },
  },
  startDate: {
    type: Date,
  },
  endDate: {
    type: Date,
  },
  isComingSoon: {
    type: Boolean,
    default: false,
  }
}, {
  timestamps: true,
  collection: 'travel_packages',
});

const TravelPackage = mongoose.model('TravelPackage', travelPackageSchema);

module.exports = TravelPackage;
