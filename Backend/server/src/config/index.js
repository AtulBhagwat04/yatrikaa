require('dotenv').config();

module.exports = {
  PORT: process.env.PORT || 3000,
  MONGODB_URI: process.env.MONGODB_URI,
  JWT_SECRET: process.env.JWT_SECRET || 'fallback_secret',
  GOOGLE_PLACES_API_KEY: process.env.GOOGLE_PLACES_API_KEY,
  GOOGLE_PLACES_BASE_URL: 'https://maps.googleapis.com/maps/api/place',
  // Default Admin Credentials (Should be set via .env)
  ADMIN_EMAIL: process.env.ADMIN_EMAIL || 'admin@example.com',
  ADMIN_PASSWORD: process.env.ADMIN_PASSWORD || 'changeme123',
  // Default SuperAdmin Credentials (Should be set via .env)
  SUPERADMIN_EMAIL: process.env.SUPERADMIN_EMAIL || 'superadmin@example.com',
  SUPERADMIN_PASSWORD: process.env.SUPERADMIN_PASSWORD || 'changeme123',
  CLOUDINARY: {
    CLOUD_NAME: process.env.CLOUD_NAME,
    API_KEY: process.env.CLOUDINARY_API_KEY,
    API_SECRET: process.env.CLOUDINARY_API_SECRET
  }
};
