/**
 * Firebase App Check Verification Middleware
 *
 * Protects endpoints from abuse by non-legitimate app clients.
 * Config flag 'enforceAppCheck' in config/limits.js allows disabling in local emulator/tests.
 */

const admin = require('firebase-admin');
const limits = require('../config/limits');
const { safeLogger } = require('./sanitizeLogs');

async function verifyAppCheck(req, res, next) {
  // If enforcement is disabled (e.g. testing or emulator)
  if (!limits.enforceAppCheck) {
    return next();
  }

  const appCheckToken = req.headers['x-firebase-appcheck'];
  const preferredLanguage = req.body?.language || req.query?.language || 'en';
  const isHindi = preferredLanguage === 'hi';

  if (!appCheckToken) {
    safeLogger.warn('App Check failed: Missing X-Firebase-AppCheck header');
    return res.status(401).json({
      error: {
        code: 'app_check_failed',
        message: isHindi
          ? 'ऐप चेक सत्यापन विफल रहा: ऐप चेक टोकन अनुपलब्ध है।'
          : 'App Check token is missing. Access denied.',
      },
    });
  }

  try {
    const appCheckClaims = await admin.appCheck().verifyToken(appCheckToken);
    req.appCheck = appCheckClaims;
    next();
  } catch (err) {
    safeLogger.warn('App Check verification failed', { message: err.message });
    return res.status(401).json({
      error: {
        code: 'app_check_failed',
        message: isHindi
          ? 'ऐप चेक सत्यापन विफल रहा: अमान्य या समाप्त टोकन।'
          : 'Invalid or expired App Check token. Access denied.',
      },
    });
  }
}

module.exports = {
  verifyAppCheck,
};
