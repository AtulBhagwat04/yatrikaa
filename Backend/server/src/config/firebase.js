const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

let serviceAccount;

try {
  // Option 1: File-based (Local development)
  serviceAccount = require('../../serviceAccountKey.json');
} catch (error) {
  // Option 2: Environment variable-based (Production - Render/Railway)
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    } catch (jsonErr) {
      console.error('CRITICAL: FIREBASE_SERVICE_ACCOUNT_JSON found but invalid JSON:', jsonErr.message);
    }
  } else if (process.env.FIREBASE_PRIVATE_KEY) {
    // Option 3: Individual environment variables
    serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    };
  }
}
if (serviceAccount && (serviceAccount.privateKey || serviceAccount.private_key)) {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin SDK initialized successfully.');
  }
} else {
  console.error('CRITICAL: Firebase Admin SDK NOT initialized. Missing credentials (JSON file or environment variables).');
}
module.exports = admin;