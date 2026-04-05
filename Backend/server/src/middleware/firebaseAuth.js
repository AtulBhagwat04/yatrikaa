const admin = require('../config/firebase');

const verifyFirebaseToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    if (!admin.apps.length) {
      return res.status(500).json({ error: 'Firebase Admin SDK not initialized on server' });
    }
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    req.firebaseUser = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying Firebase token:', error.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

module.exports = verifyFirebaseToken;
