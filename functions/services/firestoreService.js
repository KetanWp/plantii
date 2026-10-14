/**
 * Firestore Service for Scans and Feedback
 *
 * Handles persistent storage of diagnosis results in 'scans'
 * and user feedback in 'feedback'.
 */

const admin = require('firebase-admin');
const { safeLogger } = require('../middleware/sanitizeLogs');

/**
 * Saves diagnosis result into Firestore 'scans' collection
 *
 * @param {Object} params
 * @param {string} params.userId - Authenticated user UID
 * @param {string} params.cropId - Crop name / identifier
 * @param {string} params.language - 'hi' or 'en'
 * @param {Object} params.diagnosis - Validated diagnosis data
 * @returns {Promise<Object>} Saved scan record with generated id
 */
async function saveScanRecord({ userId, cropId, language, diagnosis }) {
  const scansCollection = admin.firestore().collection('scans');
  const docRef = scansCollection.doc();

  const scanRecord = {
    id: docRef.id,
    userId,
    cropId: cropId || 'general_crop',
    status: diagnosis.status || 'diseased',
    diseaseName: diagnosis.diseaseName || '',
    scientificName: diagnosis.scientificName || 'N/A',
    severity: diagnosis.severity,
    confidence: diagnosis.confidence || diagnosis.confidenceLevel || 'High',
    confidenceLevel: diagnosis.confidenceLevel || diagnosis.confidence || 'High',
    description: diagnosis.description,
    immediateActions: diagnosis.immediateActions || [],
    organicTreatments: diagnosis.organicTreatments || [],
    chemicalTreatments: diagnosis.chemicalTreatments || [],
    safetyNote: diagnosis.safetyNote || '',
    prevention: diagnosis.prevention || diagnosis.preventionTips || [],
    preventionTips: diagnosis.preventionTips || diagnosis.prevention || [],
    photoQuality: diagnosis.photoQuality || 'good',
    possibleCauses: diagnosis.possibleCauses || [],
    language: language || 'en',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await docRef.set(scanRecord);
  safeLogger.info(`Successfully stored scan record: ${docRef.id} for user: ${userId}`);

  return scanRecord;
}

/**
 * Retrieves a scan by its document ID
 *
 * @param {string} scanId
 * @returns {Promise<Object|null>}
 */
async function getScanById(scanId) {
  if (!scanId) return null;
  const doc = await admin.firestore().collection('scans').doc(scanId).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

/**
 * Saves user feedback for a verified scan
 *
 * @param {Object} params
 * @param {string} params.scanId - Scan document ID
 * @param {string} params.userId - Authenticated user UID
 * @param {boolean} params.helpful - Whether the diagnosis was helpful
 * @param {string} [params.comment] - Optional user remarks
 * @returns {Promise<string>} Created feedback document ID
 */
async function saveFeedbackRecord({ scanId, userId, helpful, comment = '' }) {
  const feedbackDocRef = admin.firestore().collection('feedback').doc();

  const feedbackData = {
    id: feedbackDocRef.id,
    scanId,
    userId,
    helpful: Boolean(helpful),
    comment: typeof comment === 'string' ? comment.trim() : '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await feedbackDocRef.set(feedbackData);
  safeLogger.info(`Successfully stored feedback ${feedbackDocRef.id} for scan: ${scanId}`);

  return feedbackDocRef.id;
}

/**
 * Records user privacy consent version and timestamp in users/{userId}
 *
 * @param {Object} params
 * @param {string} params.userId
 * @param {string} params.consentVersion
 * @returns {Promise<void>}
 */
async function recordUserConsent({ userId, consentVersion = '1.0' }) {
  const userRef = admin.firestore().collection('users').doc(userId);
  await userRef.set(
    {
      consentVersion: String(consentVersion),
      consentedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  safeLogger.info(`Successfully recorded consent v${consentVersion} for user: ${userId}`);
}

/**
 * Deletes all Firestore data associated with a user:
 * - scans collection where userId == userId
 * - feedback collection where userId == userId
 * - users/{userId} document
 *
 * @param {string} userId
 * @returns {Promise<{ deletedScans: number, deletedFeedback: number, userDocDeleted: boolean }>}
 */
async function deleteUserData(userId) {
  const db = admin.firestore();

  // 1. Delete all user scans in batches
  const scansSnapshot = await db.collection('scans').where('userId', '==', userId).get();
  let deletedScans = 0;
  if (!scansSnapshot.empty) {
    const batch = db.batch();
    scansSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
      deletedScans++;
    });
    await batch.commit();
  }

  // 2. Delete all user feedback in batches
  const feedbackSnapshot = await db.collection('feedback').where('userId', '==', userId).get();
  let deletedFeedback = 0;
  if (!feedbackSnapshot.empty) {
    const batch = db.batch();
    feedbackSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
      deletedFeedback++;
    });
    await batch.commit();
  }

  // 3. Delete user document in users/{userId}
  const userDocRef = db.collection('users').doc(userId);
  const userDoc = await userDocRef.get();
  const userDocDeleted = userDoc.exists;
  if (userDocDeleted) {
    await userDocRef.delete();
  }

  safeLogger.info(
    `Deleted data for user ${userId}: ${deletedScans} scans, ${deletedFeedback} feedback, userDoc: ${userDocDeleted}`
  );

  return {
    deletedScans,
    deletedFeedback,
    userDocDeleted,
  };
}

module.exports = {
  saveScanRecord,
  getScanById,
  saveFeedbackRecord,
  recordUserConsent,
  deleteUserData,
};
