const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const config = require('./config');
const placesRoutes = require('./routes/placesRoutes');
const authRoutes = require('./routes/authRoutes');
const postRoutes = require('./routes/postRoutes');
const eventRoutes = require('./routes/eventRoutes');
const packageRoutes = require('./routes/packageRoutes');
const seedAdmins = require('./data/seedAdmin');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Database Connection
mongoose.connect(config.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB successfully');
    await seedAdmins();
  })
  .catch((err) => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/places', placesRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/packages', packageRoutes);

// Base route for health check
app.get('/', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Yatrikaa API is running...' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', uptime: process.uptime() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('[error]', err.message);

  // Mongoose validation error — show which fields failed
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(e => e.message);
    return res.status(400).json({ error: messages.join(', ') });
  }

  // Mongoose cast error (invalid ObjectId)
  if (err.name === 'CastError') {
    return res.status(400).json({ error: `Invalid ${err.path}: ${err.value}` });
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    return res.status(400).json({ error: `Duplicate value for field: ${field}` });
  }

  res.status(err.statusCode || 500).json({ error: err.message || 'Something went wrong!' });
});

module.exports = app;
