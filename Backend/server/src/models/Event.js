const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  startTime: {
    type: String,
    required: true
  },
  endTime: {
    type: String
  },
  venue: {
    type: String,
    required: true
  },
  address: {
    type: String,
    required: true
  },
  geometry: {
    location: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true }
    }
  },
  category: {
    type: String,
    required: true
  },
  images: [{
    type: String
  }],
  organizer: {
    type: String
  },
  entryFee: {
    type: String,
    default: 'Free'
  },
  contactNumber: {
    type: String
  },
  website: {
    type: String
  },
  isPopular: {
    type: Boolean,
    default: false
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  interestedCount: {
    type: Number,
    default: 0
  },
  interestedUsers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }]
}, {
  timestamps: true,
  collection: 'events'
});

const Event = mongoose.model('Event', eventSchema);

module.exports = Event;
