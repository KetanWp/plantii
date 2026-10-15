/**
 * POST /diagnose route handler
 *
 * Coordinates:
 * 1. Global Daily Cap check & atomic transaction on stats/{date}
 * 2. User Daily Limit check & atomic transaction on users/{uid} (Asia/Kolkata timezone)
 * 3. Gemini Vision AI analysis (~45s timeout)
 * 4. Automatic scan quota refund on AI failure
 * 5. Firestore persistence in 'scans' collection
 * 6. Preserves exact Diagnosis response format
 */

const limits = require('../config/limits');
const { analyzeCropLeaf } = require('../services/aiService');
const { saveScanRecord } = require('../services/firestoreService');
const {
  checkAndIncrementGlobalDailyCap,
  checkAndIncrementUserDailyLimit,
  refundScan,
  getKolkataDateString,
} = require('../services/scanQuotaService');
const { safeLogger } = require('../middleware/sanitizeLogs');

/**
 * Creates diagnosis handler with access to AI secret accessor
 * @param {Function} getApiKey - Function returning the AI API key
 */
function createDiagnoseHandler(getApiKey) {
  return async function handleDiagnose(req, res) {
    const userId = req.user.uid;
    const crop = req.body.crop;
    const language = req.body.language;
    const isHindi = language === 'hi';
    const { buffer: imageBuffer, mimeType } = req.parsedImage;
    const todayDateStr = getKolkataDateString();

    // 1. Check Global Daily Cap across all users (Emergency Brake)
    const globalCapResult = await checkAndIncrementGlobalDailyCap(todayDateStr);
    if (!globalCapResult.allowed) {
      safeLogger.warn(`Global daily cap reached: ${limits.globalDailyCap} scans on ${todayDateStr}`);
      return res.status(503).json({
        error: {
          code: 'service_busy',
          message: isHindi
            ? 'सर्वर पर वर्तमान में अत्यधिक ट्रैफ़िक है। कृपया कुछ समय बाद पुनः प्रयास करें।'
            : 'The service is temporarily busy due to high demand. Please try again later.',
        },
      });
    }

    // 2. Check & Increment User Daily Limit (users/{uid} transaction in Asia/Kolkata)
    const userLimitResult = await checkAndIncrementUserDailyLimit(userId, todayDateStr);
    if (!userLimitResult.allowed) {
      // Refund the global cap since this user's scan won't proceed
      await refundScan({ userId: 'none', dateStr: todayDateStr });

      safeLogger.warn(`Daily limit reached for user: ${userId} (${limits.userDailyLimit} scans on ${todayDateStr})`);
      return res.status(429).json({
        error: {
          code: 'rate_limited',
          message: isHindi
            ? `दैनिक स्कैन सीमा समाप्त हो गई है (अधिकतम ${limits.userDailyLimit} स्कैन प्रतिदिन)। कृपया कल पुनः प्रयास करें।`
            : `Daily scan limit reached (maximum ${limits.userDailyLimit} scans per day). Please try again tomorrow.`,
          limit: userLimitResult.limit,
          resetsAt: userLimitResult.resetsAt,
        },
      });
    }

    // 3. Execute AI Vision diagnosis with ~45s timeout
    let diagnosisResult;
    try {
      const apiKey = getApiKey();
      if (!apiKey) {
        throw new Error('Gemini API key is missing. Set GEMINI_API_KEY secret.');
      }

      diagnosisResult = await analyzeCropLeaf({
        apiKey,
        imageBuffer,
        mimeType,
        crop,
        language,
      });
    } catch (aiErr) {
      // AI call failed or timed out: Refund user and global quota immediately!
      await refundScan({ userId, dateStr: todayDateStr });

      if (aiErr.code === 'timeout' || aiErr.status === 504) {
        safeLogger.warn('Diagnosis AI call timed out; refunded scan quota', { userId });
        return res.status(504).json({
          error: {
            code: 'timeout',
            message: isHindi
              ? 'अनुरोध का समय समाप्त हो गया। कृपया पुनः प्रयास करें।'
              : 'The diagnosis request timed out after 45 seconds. Please try again.',
          },
        });
      }

      if (aiErr.code === 'quota_exceeded' || aiErr.status === 503) {
        safeLogger.warn('Gemini quota exceeded; refunded scan quota', { userId });
        return res.status(503).json({
          error: {
            code: 'service_busy',
            message: isHindi
              ? 'एआई सेवा वर्तमान में व्यस्त है। कृपया कुछ समय बाद पुनः प्रयास करें।'
              : 'AI diagnosis service is temporarily busy. Please try again shortly.',
          },
        });
      }

      if (aiErr.code === 'safety_block' || aiErr.status === 400) {
        safeLogger.warn('Gemini safety block triggered; refunded scan quota', { userId });
        return res.status(400).json({
          error: {
            code: 'bad_image',
            message: isHindi
              ? 'सुरक्षा नियमों के कारण फोटो संसाधित नहीं हो सकी। कृपया पत्ती की स्पष्ट फोटो लें।'
              : 'The leaf photo could not be processed due to safety guidelines. Please take a clear photo of the plant leaf.',
          },
        });
      }

      safeLogger.error('AI diagnosis analysis failed; refunded scan quota', {
        userId,
        errorCode: aiErr.code,
      });

      return res.status(502).json({
        error: {
          code: 'ai_failed',
          message: isHindi
            ? 'पौधे की जांच करने में समस्या आई। कृपया स्पष्ट फोटो के साथ पुनः प्रयास करें।'
            : 'Failed to analyze crop leaf. Please retry with a clearer photo.',
        },
      });
    }

    // 4. Persist result in Firestore 'scans' collection
    try {
      const savedScan = await saveScanRecord({
        userId,
        cropId: crop,
        language,
        diagnosis: diagnosisResult,
      });

      safeLogger.info(`Successfully completed scan ${savedScan.id} for user ${userId} (${savedScan.diseaseName})`);

      // 5. Return diagnosis matching client model format exactly
      return res.status(200).json({
        id: savedScan.id,
        cropId: savedScan.cropId,
        detectedCrop: savedScan.detectedCrop || diagnosisResult.detectedCrop || 'Unknown Plant',
        status: savedScan.status || diagnosisResult.status || 'diseased',
        diseaseName: savedScan.diseaseName,
        scientificName: savedScan.scientificName,
        severity: savedScan.severity,
        confidence: savedScan.confidence,
        confidenceLevel: savedScan.confidenceLevel,
        description: savedScan.description,
        immediateActions: savedScan.immediateActions,
        organicTreatments: savedScan.organicTreatments,
        chemicalTreatments: savedScan.chemicalTreatments,
        safetyNote: savedScan.safetyNote,
        prevention: savedScan.prevention,
        preventionTips: savedScan.preventionTips,
        photoQuality: savedScan.photoQuality,
        possibleCauses: savedScan.possibleCauses,
        language: savedScan.language,
      });
    } catch (saveErr) {
      safeLogger.error('Failed to save scan record to Firestore', { message: saveErr.message });
      // Even if Firestore save had an issue, return diagnosis result so user gets their answer
      return res.status(200).json({
        id: `scan_${Date.now()}`,
        cropId: crop || diagnosisResult.detectedCrop || 'general_crop',
        detectedCrop: diagnosisResult.detectedCrop || 'Unknown Plant',
        status: diagnosisResult.status || 'diseased',
        diseaseName: diagnosisResult.diseaseName,
        scientificName: diagnosisResult.scientificName || 'N/A',
        severity: diagnosisResult.severity,
        confidence: diagnosisResult.confidence,
        confidenceLevel: diagnosisResult.confidenceLevel,
        description: diagnosisResult.description,
        immediateActions: diagnosisResult.immediateActions || [],
        organicTreatments: diagnosisResult.organicTreatments || [],
        chemicalTreatments: diagnosisResult.chemicalTreatments || [],
        safetyNote: diagnosisResult.safetyNote || '',
        prevention: diagnosisResult.prevention || [],
        preventionTips: diagnosisResult.preventionTips || [],
        photoQuality: diagnosisResult.photoQuality || 'good',
        possibleCauses: diagnosisResult.possibleCauses || [],
        language: language,
      });
    }
  };
}

module.exports = {
  createDiagnoseHandler,
};
