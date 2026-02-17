require('dotenv').config();

module.exports = {
  PORT: process.env.PORT || 3000,
  GOOGLE_PLACES_API_KEY: process.env.GOOGLE_PLACES_API_KEY,
  GOOGLE_PLACES_BASE_URL: 'https://maps.googleapis.com/maps/api/place'
};
