const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  password: {
    type: String,
    required: false,
    minlength: 6
  },
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true
  },
  fcmToken: {
    type: String,
    trim: true
  },
  role: {
    type: String,
    enum: ['user', 'admin', 'guide'],
    default: 'user'
  },
  guideRequestStatus: {
    type: String,
    enum: ['None', 'Pending', 'Approved', 'Rejected'],
    default: 'None'
  },
  tripsCount: {
    type: Number,
    default: 0
  },
  savedCount: {
    type: Number,
    default: 0
  },
  reviewsCount: {
    type: Number,
    default: 0
  },
  postsCount: {
    type: Number,
    default: 0
  },
  packagesCount: {
    type: Number,
    default: 0
  },
  favoritePlaces: {
    type: [String],
    default: []
  },
  phoneNumber: {
    type: String,
    trim: true
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other', 'Prefer not to say'],
    default: 'Prefer not to say'
  },
  profilePicture: {
    type: String
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

const User = mongoose.model('User', userSchema);

module.exports = User;
