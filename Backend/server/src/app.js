const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const config = require('./config');
const placesRoutes = require('./routes/placesRoutes');
const authRoutes = require('./routes/authRoutes');
const postRoutes = require('./routes/postRoutes');
const eventRoutes = require('./routes/eventRoutes');
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

// Base route for health check
app.get('/', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Bhatkanti API is running...' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', uptime: process.uptime() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

module.exports = app;
