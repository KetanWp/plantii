/**
 * POST /diagnose route handler
 *
 * Coordinates authentication, rate limiting, image validation,
 * AI vision diagnosis, timeout handling, and Firestore persistence.
 */

const { analyzeCropLeaf } = require('../services/aiService');
const { saveScanRecord } = require('../services/firestoreService');
const { safeLogger } = require('../middleware/sanitizeLogs');

// 55-second application-level timeout to cleanly return JSON before 60s function limit
const DIAGNOSIS_TIMEOUT_MS = 55000;

/**
 * Creates diagnosis handler with access to AI secret accessor
 * @param {Function} getApiKey - Function returning the AI API key
 */
function createDiagnoseHandler(getApiKey) {
  return async function handleDiagnose(req, res) {
    const userId = req.user.uid;
    const crop = (req.body.crop || 'crop').toLowerCase().trim();
    const language = (req.body.language || 'en').toLowerCase().trim() === 'hi' ? 'hi' : 'en';
    const isHindi = language === 'hi';

    const { buffer: imageBuffer, mimeType } = req.parsedImage;

    // Timeout promise to catch hanging network/AI calls before function kill
    let timeoutHandle;
    const timeoutPromise = new Promise((_, reject) => {
      timeoutHandle = setTimeout(() => {
        const timeoutErr = new Error('Diagnosis processing timed out');
        timeoutErr.code = 'timeout';
        reject(timeoutErr);
      }, DIAGNOSIS_TIMEOUT_MS);
    });

    try {
      const apiKey = getApiKey();
      if (!apiKey) {
        throw new Error('AI API key is missing. Set AI_API_KEY secret.');
      }

      // Execute AI vision diagnosis with timeout race
      const diagnosisResult = await Promise.race([
        analyzeCropLeaf({
          apiKey,
          imageBuffer,
          mimeType,
          crop,
          language,
        }),
        timeoutPromise,
      ]);

      clearTimeout(timeoutHandle);

      // Persist result to Firestore 'scans' collection
      const savedScan = await saveScanRecord({
        userId,
        cropId: crop,
        language,
        diagnosis: diagnosisResult,
      });

      safeLogger.info(`Successfully completed diagnosis scan: ${savedScan.id} for user: ${userId}`);

      return res.status(200).json({
        id: savedScan.id,
        cropId: savedScan.cropId,
        diseaseName: savedScan.diseaseName,
        scientificName: savedScan.scientificName,
        severity: savedScan.severity,
        confidenceLevel: savedScan.confidenceLevel,
        description: savedScan.description,
        immediateActions: savedScan.immediateActions,
        organicTreatments: savedScan.organicTreatments,
        chemicalTreatments: savedScan.chemicalTreatments,
        safetyNote: savedScan.safetyNote,
        preventionTips: savedScan.preventionTips,
        language: savedScan.language,
      });
    } catch (err) {
      clearTimeout(timeoutHandle);

      // Rollback daily rate count so user is not penalized for backend failures
      if (typeof req.rollbackDailyUsage === 'function') {
        await req.rollbackDailyUsage();
      }

      // Case 1: Timeout error
      if (err.code === 'timeout') {
        safeLogger.error('Diagnosis request timed out after 55+ seconds');
        return res.status(504).json({
          error: {
            code: 'timeout',
            message: isHindi
              ? 'अनुरोध का समय समाप्त हो गया (60 सेकंड)। कृपया पुनः प्रयास करें।'
              : 'The diagnosis request timed out after 60 seconds. Please try again.',
          },
        });
      }

      // Case 2: AI failure after retry
      if (err.code === 'ai_failed') {
        safeLogger.error('AI diagnosis analysis failed after retry');
        return res.status(502).json({
          error: {
            code: 'ai_failed',
            message: isHindi
              ? 'पौधे की जांच करने में समस्या आई। कृपया स्पष्ट फोटो के साथ पुनः प्रयास करें।'
              : 'Failed to analyze crop leaf. Please retry with a clearer photo.',
          },
        });
      }

      // Case 3: Other unexpected errors
      safeLogger.error('Unhandled diagnosis error', { message: err.message });
      return res.status(500).json({
        error: {
          code: 'ai_failed',
          message: isHindi
            ? 'निदान पूरा करने में असमर्थ। कृपया पुनः प्रयास करें।'
            : 'Unable to complete diagnosis. Please try again.',
        },
      });
    }
  };
}

module.exports = {
  createDiagnoseHandler,
  DIAGNOSIS_TIMEOUT_MS,
};
