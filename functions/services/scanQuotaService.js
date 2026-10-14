/**
 * Scan Quota & Rate Limiting Service
 *
 * Implements:
 * 1. Daily Limit Per User (Firestore transaction on users/{uid} with scanCount & scanDate in Asia/Kolkata)
 * 2. Global Daily Cap (Firestore transaction on stats/{date})
 * 3. Count Refunds when AI calls fail
 */

const admin = require('firebase-admin');
const limits = require('../config/limits');
const { getKolkataDateString, getKolkataMidnightReset } = require('../utils/timezone');
const { safeLogger } = require('../middleware/sanitizeLogs');

/**
 * Checks and increments global daily cap across all users
 *
 * @param {string} dateStr - Date string in Asia/Kolkata (YYYY-MM-DD)
 * @returns {Promise<{ allowed: boolean, count?: number }>}
 */
async function checkAndIncrementGlobalDailyCap(dateStr) {
  const statsRef = admin.firestore().collection('stats').doc(dateStr);

  return admin.firestore().runTransaction(async (transaction) => {
    const doc = await transaction.get(statsRef);
    const count = doc.exists ? (doc.data().scanCount || 0) : 0;

    if (count >= limits.globalDailyCap) {
      return { allowed: false, count };
    }

    const expireAt = new Date(Date.now() + limits.statsRetentionDays * 24 * 60 * 60 * 1000);

    transaction.set(
      statsRef,
      {
        date: dateStr,
        scanCount: count + 1,
        expireAt,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { allowed: true, count: count + 1 };
  });
}

/**
 * Checks and increments user daily limit in users/{uid}
 *
 * @param {string} userId - Authenticated user UID
 * @param {string} dateStr - Date string in Asia/Kolkata (YYYY-MM-DD)
 * @returns {Promise<{ allowed: boolean, count?: number, limit: number, resetsAt: string }>}
 */
async function checkAndIncrementUserDailyLimit(userId, dateStr) {
  const userRef = admin.firestore().collection('users').doc(userId);
  const resetsAt = getKolkataMidnightReset();

  return admin.firestore().runTransaction(async (transaction) => {
    const doc = await transaction.get(userRef);
    const data = doc.exists ? doc.data() : {};

    let currentCount = 0;
    // If scanDate matches today's date in Asia/Kolkata, use existing count
    if (data.scanDate === dateStr) {
      currentCount = data.scanCount || 0;
    } else {
      // If scanDate is not today, reset count to 0
      currentCount = 0;
    }

    if (currentCount >= limits.userDailyLimit) {
      return {
        allowed: false,
        limit: limits.userDailyLimit,
        resetsAt,
        count: currentCount,
      };
    }

    transaction.set(
      userRef,
      {
        scanCount: currentCount + 1,
        scanDate: dateStr,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      allowed: true,
      count: currentCount + 1,
      limit: limits.userDailyLimit,
      resetsAt,
    };
  });
}

/**
 * Refunds scan counts on both users/{uid} and stats/{date} if an AI call fails
 *
 * @param {Object} params
 * @param {string} params.userId
 * @param {string} params.dateStr
 */
async function refundScan({ userId, dateStr }) {
  const userRef = admin.firestore().collection('users').doc(userId);
  const statsRef = admin.firestore().collection('stats').doc(dateStr);

  try {
    await admin.firestore().runTransaction(async (transaction) => {
      // 1. Refund user
      const userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.scanDate === dateStr && (userData.scanCount || 0) > 0) {
          transaction.update(userRef, {
            scanCount: admin.firestore.FieldValue.increment(-1),
          });
        }
      }

      // 2. Refund global stats
      const statsDoc = await transaction.get(statsRef);
      if (statsDoc.exists) {
        const statsData = statsDoc.data();
        if ((statsData.scanCount || 0) > 0) {
          transaction.update(statsRef, {
            scanCount: admin.firestore.FieldValue.increment(-1),
          });
        }
      }
    });

    safeLogger.info(`Successfully refunded scan quota for user: ${userId} on date: ${dateStr}`);
  } catch (err) {
    safeLogger.error('Failed to refund scan quota after error', { message: err.message });
  }
}

module.exports = {
  checkAndIncrementGlobalDailyCap,
  checkAndIncrementUserDailyLimit,
  refundScan,
  getKolkataDateString,
  getKolkataMidnightReset,
};
