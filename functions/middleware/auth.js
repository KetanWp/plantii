/**
 * Firebase Authentication Verification Middleware
 *
 * Verifies standard 'Authorization: Bearer <ID_TOKEN>' header
 * Rejects with 401 and error code 'unauthorized' if missing or invalid.
 */

const admin = require('firebase-admin');
const { safeLogger } = require('./sanitizeLogs');

async function verifyAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  const preferredLanguage = req.body?.language || req.query?.language || 'en';
  const isHindi = preferredLanguage === 'hi';

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    safeLogger.warn('Unauthorized request attempt: Missing or invalid Authorization header');
    return res.status(401).json({
      error: {
        code: 'unauthorized',
        message: isHindi
          ? 'प्रमाणीकरण आवश्यक है। कृपया ऐप में लॉग इन करें।'
          : 'Authentication token is missing or invalid. Please sign in.',
      },
    });
  }

  const idToken = authHeader.split('Bearer ')[1].trim();

  if (!idToken) {
    safeLogger.warn('Unauthorized request attempt: Empty Bearer token');
    return res.status(401).json({
      error: {
        code: 'unauthorized',
        message: isHindi
          ? 'अमान्य प्रमाणीकरण टोकन।'
          : 'Invalid authentication token provided.',
      },
    });
  }

  // In local emulator mode, accept test-token-<uid> for automated testing
  if (process.env.FUNCTIONS_EMULATOR === 'true' && idToken.startsWith('test-token-')) {
    const uid = idToken.replace('test-token-', '') || 'test_farmer_uid';
    req.user = { uid, email: `${uid}@emulator.local` };
    safeLogger.info(`Emulator test authenticated for user: ${uid}`);
    return next();
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    safeLogger.info(`Authenticated request for user: ${decodedToken.uid}`);
    next();
  } catch (err) {
    safeLogger.warn('Token verification failed', { errorCode: err.code, errorMessage: err.message });
    return res.status(401).json({
      error: {
        code: 'unauthorized',
        message: isHindi
          ? 'आपका सत्र समाप्त हो गया है। कृपया पुनः लॉग इन करें।'
          : 'Your session has expired or is invalid. Please sign in again.',
      },
    });
  }
}

module.exports = {
  verifyAuth,
};
