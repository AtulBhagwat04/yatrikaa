const express = require('express');
const cors = require('cors');
const placesRoutes = require('./routes/placesRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Request logger
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/api/places', placesRoutes);

// Base route for health check
app.get('/', (req, res) => {
  res.json({ message: 'Bhatkanti API is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

module.exports = app;
