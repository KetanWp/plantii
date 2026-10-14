/**
 * Routes for Consent Recording and Account Deletion
 *
 * POST   /consent - Records user privacy policy consent on users/{uid}
 * DELETE /account - Deletes user's scans, feedback, users/{uid} doc, and Auth user
 */

const admin = require('firebase-admin');
const { recordUserConsent, deleteUserData } = require('../services/firestoreService');
const { safeLogger } = require('../middleware/sanitizeLogs');

/**
 * Handles recording privacy consent on the backend
 */
async function handleConsent(req, res) {
  const userId = req.user?.uid;
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';

  if (!userId) {
    return res.status(401).json({
      error: {
        code: 'unauthorized',
        message: isHindi
          ? 'प्रमाणीकरण आवश्यक है।'
          : 'Authentication is required.',
      },
    });
  }

  const rawVersion = req.body?.consentVersion;
  const consentVersion = typeof rawVersion === 'string' && rawVersion.trim().length > 0
    ? rawVersion.trim().substring(0, 16)
    : '1.0';

  try {
    await recordUserConsent({ userId, consentVersion });
    return res.status(200).json({
      success: true,
      consentVersion,
      message: isHindi
        ? 'सहमति सफलतापूर्वक दर्ज की गई।'
        : 'Consent recorded successfully.',
    });
  } catch (err) {
    safeLogger.error('Failed to record consent', { userId, message: err.message });
    return res.status(500).json({
      error: {
        code: 'server_error',
        message: isHindi
          ? 'सहमति सहेजने में विफल। कृपया पुनः प्रयास करें।'
          : 'Failed to record consent. Please try again.',
      },
    });
  }
}

/**
 * Handles full account and data deletion for Play Store compliance
 */
async function handleDeleteAccount(req, res) {
  const userId = req.user?.uid;
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';

  if (!userId) {
    return res.status(401).json({
      error: {
        code: 'unauthorized',
        message: isHindi
          ? 'प्रमाणीकरण आवश्यक है।'
          : 'Authentication is required.',
      },
    });
  }

  safeLogger.info(`Account deletion requested for user: ${userId}`);

  // 1. Delete Firestore data (scans, feedback, users doc)
  let deletionStats;
  try {
    deletionStats = await deleteUserData(userId);
  } catch (dbErr) {
    safeLogger.error('Failed to delete Firestore data during account deletion', {
      userId,
      message: dbErr.message,
    });
    return res.status(500).json({
      error: {
        code: 'database_deletion_failed',
        message: isHindi
          ? 'डेटाबेस से उपयोगकर्ता डेटा हटाने में विफल। कृपया पुनः प्रयास करें।'
          : 'Failed to delete user records from the database. Please try again.',
      },
    });
  }

  // 2. Delete Firebase Auth user record
  try {
    await admin.auth().deleteUser(userId);
    safeLogger.info(`Successfully deleted Firebase Auth user: ${userId}`);
  } catch (authErr) {
    // If the user was already deleted from Auth or does not exist
    if (authErr.code === 'auth/user-not-found') {
      safeLogger.warn(`Auth user ${userId} not found; treating as already deleted.`);
    } else {
      safeLogger.error('Failed to delete Firebase Auth user after Firestore deletion', {
        userId,
        message: authErr.message,
        code: authErr.code,
      });

      return res.status(500).json({
        error: {
          code: 'partial_failure',
          message: isHindi
            ? 'आपका डेटा हटा दिया गया, लेकिन प्रमाणीकरण खाता हटाने में समस्या आई।'
            : 'Your data was deleted, but deleting the authentication account encountered an error.',
          details: {
            firestoreDeleted: true,
            authDeleted: false,
          },
        },
      });
    }
  }

  return res.status(200).json({
    success: true,
    message: isHindi
      ? 'आपका खाता और सभी संबंधित डेटा स्थायी रूप से हटा दिया गया है।'
      : 'Your account and all associated data have been permanently deleted.',
    deleted: deletionStats,
  });
}

module.exports = {
  handleConsent,
  handleDeleteAccount,
};
