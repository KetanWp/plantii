/**
 * Per-IP Rate Limiting Middleware
 *
 * Enforces max 30 requests per IP per hour using hashed IPs.
 * NEVER stores raw IP addresses in Firestore.
 */

const crypto = require('crypto');
const admin = require('firebase-admin');
const limits = require('../config/limits');
const { safeLogger } = require('./sanitizeLogs');

/**
 * Creates one-way SHA-256 hash of an IP address with a secret salt
 * @param {string} ip
 * @returns {string} 64-char hex string
 */
function hashIp(ip) {
  return crypto
    .createHash('sha256')
    .update(`${ip}_${limits.ipSalt}`)
    .digest('hex');
}

/**
 * Extracts client IP safely from request headers
 * @param {Object} req
 * @returns {string}
 */
function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded && typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim();
  }
  return req.socket?.remoteAddress || req.ip || '127.0.0.1';
}

/**
 * Middleware enforcing hourly per-IP limits
 */
async function checkIpRateLimit(req, res, next) {
  const rawIp = getClientIp(req);
  const hashedIp = hashIp(rawIp);
  const windowHour = Math.floor(Date.now() / limits.ipWindowMs);
  const docId = `${hashedIp.substring(0, 32)}_${windowHour}`;
  const ipRef = admin.firestore().collection('ip_limits').doc(docId);
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';

  try {
    const isAllowed = await admin.firestore().runTransaction(async (transaction) => {
      const doc = await transaction.get(ipRef);
      const currentCount = doc.exists ? (doc.data().count || 0) : 0;

      if (currentCount >= limits.perIpHourlyLimit) {
        return false;
      }

      const expireAtDate = new Date(Date.now() + limits.ipLimitRetentionDays * 24 * 60 * 60 * 1000);

      transaction.set(
        ipRef,
        {
          hashedIp,
          count: currentCount + 1,
          windowHour,
          expireAt: expireAtDate,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return true;
    });

    if (!isAllowed) {
      safeLogger.warn(`Per-IP hourly limit reached for hashed IP: ${hashedIp.substring(0, 8)}...`);
      return res.status(429).json({
        error: {
          code: 'rate_limited',
          message: isHindi
            ? 'इस नेटवर्क से बहुत अधिक अनुरोध प्राप्त हुए हैं। कृपया कुछ समय बाद पुनः प्रयास करें।'
            : 'Too many requests from this network. Please try again later.',
          limit: limits.perIpHourlyLimit,
        },
      });
    }

    next();
  } catch (err) {
    safeLogger.error('Error during IP rate limit transaction', { message: err.message });
    // Fail-open or return error? Typically log and proceed to not block valid users on DB glitch
    next();
  }
}

module.exports = {
  checkIpRateLimit,
  hashIp,
  getClientIp,
};
