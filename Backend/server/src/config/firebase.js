const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

// The user should provide their serviceAccountKey.json path in the .env
// We'll try to find it or initialize with default credentials if available
let serviceAccount;
try {
  serviceAccount = require('../../serviceAccountKey.json');
} catch (error) {
  console.warn('Firebase serviceAccountKey.json not found. Using environment variables.');
  // Fallback to environment variables if possible, but for Admin SDK we usually need a JSON.
  // We specify it's required for this feature.
}

if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  console.error('CRITICAL: Firebase could not be initialized because serviceAccountKey.json is missing.');
}

module.exports = admin;
