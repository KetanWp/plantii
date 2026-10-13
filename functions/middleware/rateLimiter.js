/**
 * Daily Rate Limiter Middleware
 *
 * Enforces max 10 scans per user per calendar day (UTC/IST tracked in Firestore).
 * Rejects with 429 status and error code 'rate_limited'.
 */

const admin = require('firebase-admin');
const { safeLogger } = require('./sanitizeLogs');

const MAX_DAILY_SCANS = 10;

/**
 * Returns today's date formatted as YYYY-MM-DD in UTC
 */
function getTodayDateKey() {
  const now = new Date();
  return now.toISOString().split('T')[0];
}

/**
 * Checks if the user has exceeded the daily limit of scans.
 * Atomically increments the scan count in a Firestore transaction.
 */
async function checkDailyRateLimit(req, res, next) {
  const userId = req.user?.uid;
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';

  if (!userId) {
    return res.status(401).json({
      error: {
        code: 'unauthorized',
        message: isHindi
          ? 'प्रमाणीकरण आवश्यक है।'
          : 'User authentication required.',
      },
    });
  }

  const dateKey = getTodayDateKey();
  const usageDocId = `${userId}_${dateKey}`;
  const usageRef = admin.firestore().collection('daily_usage').doc(usageDocId);

  try {
    const isAllowed = await admin.firestore().runTransaction(async (transaction) => {
      const doc = await transaction.get(usageRef);
      const currentCount = doc.exists ? (doc.data().count || 0) : 0;

      if (currentCount >= MAX_DAILY_SCANS) {
        return false;
      }

      transaction.set(
        usageRef,
        {
          userId,
          date: dateKey,
          count: currentCount + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return true;
    });

    if (!isAllowed) {
      safeLogger.warn(`Daily rate limit exceeded for user: ${userId} on date: ${dateKey}`);
      return res.status(429).json({
        error: {
          code: 'rate_limited',
          message: isHindi
            ? 'दैनिक स्कैन सीमा समाप्त हो गई है (अधिकतम 10 स्कैन प्रतिदिन)। कृपया कल पुनः प्रयास करें।'
            : 'Daily scan limit reached (maximum 10 scans per day). Please try again tomorrow.',
          limit: MAX_DAILY_SCANS,
          remaining: 0,
        },
      });
    }

    // Attach rollback function to request in case AI fails, so user is not unfairly penalized
    req.rollbackDailyUsage = async () => {
      try {
        await usageRef.update({
          count: admin.firestore.FieldValue.increment(-1),
        });
        safeLogger.info(`Rolled back daily usage for user: ${userId}`);
      } catch (err) {
        safeLogger.error('Failed to rollback usage', { message: err.message });
      }
    };

    next();
  } catch (err) {
    safeLogger.error('Error in rate limiter transaction', { message: err.message });
    return res.status(500).json({
      error: {
        code: 'server_error',
        message: isHindi
          ? 'सर्वर पर दर सीमा जांचने में त्रुटि हुई।'
          : 'Error validating daily usage rate limit.',
      },
    });
  }
}

module.exports = {
  checkDailyRateLimit,
  MAX_DAILY_SCANS,
};
