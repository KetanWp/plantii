/**
 * POST /feedback route handler
 *
 * Verifies authenticated user ownership of the scan record
 * and persists feedback in the 'feedback' collection.
 */

const { getScanById, saveFeedbackRecord } = require('../services/firestoreService');
const { safeLogger } = require('../middleware/sanitizeLogs');

async function handleFeedback(req, res) {
  const userId = req.user.uid;
  const { scanId, helpful, comment } = req.body || {};
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';

  if (!scanId || typeof scanId !== 'string') {
    return res.status(400).json({
      error: {
        code: 'bad_request',
        message: isHindi
          ? 'स्कैन आईडी आवश्यक है।'
          : 'scanId is required.',
      },
    });
  }

  if (typeof helpful !== 'boolean') {
    return res.status(400).json({
      error: {
        code: 'bad_request',
        message: isHindi
          ? 'helpful मान (सत्य या असत्य) आवश्यक है।'
          : 'helpful must be a boolean (true or false).',
      },
    });
  }

  try {
    const scan = await getScanById(scanId);

    if (!scan) {
      safeLogger.warn(`Feedback rejected: Scan not found: ${scanId}`);
      return res.status(404).json({
        error: {
          code: 'not_found',
          message: isHindi
            ? 'स्कैन रिकॉर्ड नहीं मिला।'
            : 'Scan record not found.',
        },
      });
    }

    if (scan.userId !== userId) {
      safeLogger.warn(`Feedback rejected: User ${userId} does not own scan ${scanId}`);
      return res.status(403).json({
        error: {
          code: 'forbidden',
          message: isHindi
            ? 'आपको इस स्कैन के लिए फ़ीडबैक सबमिट करने की अनुमति नहीं है।'
            : 'You do not have permission to submit feedback for this scan.',
        },
      });
    }

    const feedbackId = await saveFeedbackRecord({
      scanId,
      userId,
      helpful,
      comment: typeof comment === 'string' ? comment : '',
    });

    return res.status(200).json({
      success: true,
      feedbackId,
      message: isHindi
        ? 'फ़ीडबैक सफलतापूर्वक सहेजा गया। धन्यवाद!'
        : 'Feedback submitted successfully. Thank you!',
    });
  } catch (err) {
    safeLogger.error('Error handling feedback', { message: err.message });
    return res.status(500).json({
      error: {
        code: 'server_error',
        message: isHindi
          ? 'फ़ीडबैक सहेजने में विफल।'
          : 'Failed to record feedback. Please try again.',
      },
    });
  }
}

module.exports = {
  handleFeedback,
};
