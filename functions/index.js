/**
 * Firebase Cloud Functions (2nd gen) Backend for Plantii
 *
 * Hardened with:
 * 1. Daily User Limit (10 scans/day on users/{uid} in Asia/Kolkata timezone with refund on failure)
 * 2. Strict Image Limits (<= 1.5MB after decode, JPEG/PNG magic bytes check, Express early rejection)
 * 3. Execution Settings (60s timeout, 512MiB RAM, maxInstances: 10, region: asia-south1, ~45s Gemini timeout)
 * 4. Global Daily Cap (2000 scans/day emergency brake on stats/{date})
 * 5. Per-IP Rate Limit (30 reqs/hour with hashed IPs)
 * 6. Firebase App Check enforcement on /diagnose & /feedback (configurable bypass for local tests)
 * 7. Safety (redacts images, keys, AI responses; validates crops & languages; auto-cleanup)
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const express = require('express');
const cors = require('cors');
const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');

// Import centralized limits configuration
const limits = require('./config/limits');

// Import middlewares
const { verifyAuth } = require('./middleware/auth');
const { verifyAppCheck } = require('./middleware/appCheck');
const { checkIpRateLimit } = require('./middleware/ipRateLimiter');
const { validateDiagnoseInputs } = require('./middleware/validateInputs');
const { parseAndValidateImage } = require('./middleware/imageParser');
const { sanitizeRequestLogging, safeLogger } = require('./middleware/sanitizeLogs');

// Import route handlers
const { createDiagnoseHandler } = require('./routes/diagnose');
const { handleFeedback } = require('./routes/feedback');

// Define Firebase Secret for Gemini API key (never hardcoded in code)
const geminiApiKeySecret = defineSecret('GEMINI_API_KEY');

// Helper to retrieve the secret safely in production or local emulator
function getGeminiApiKey() {
  try {
    return geminiApiKeySecret.value() || process.env.GEMINI_API_KEY || '';
  } catch (err) {
    return process.env.GEMINI_API_KEY || '';
  }
}

// Create Express application
const app = express();

// Global Middlewares
app.use(cors({ origin: true }));
app.use(sanitizeRequestLogging);

// Express body limit configured to reject oversized requests early
app.use(express.json({ limit: limits.expressBodyLimit }));
app.use(express.urlencoded({ extended: true, limit: limits.expressBodyLimit }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'Plantii Backend (2nd gen - Hardened)',
    region: limits.region,
    dailyLimit: limits.userDailyLimit,
    globalCap: limits.globalDailyCap,
    maxImageMb: Number((limits.maxImageBytes / (1024 * 1024)).toFixed(1)),
    appCheckEnforced: limits.enforceAppCheck,
    timestamp: new Date().toISOString(),
  });
});

// POST /diagnose
// 1. Verify App Check token
// 2. Verify Firebase Auth token
// 3. Check Per-IP rate limit (30 reqs/hr)
// 4. Validate inputs (crop from allowed list, language hi/en)
// 5. Parse & validate image (<= 1.5MB after decode, JPEG/PNG magic bytes)
// 6. Check Global Daily Cap (2000/day) & User Daily Limit (10/day in Asia/Kolkata)
// 7. Execute Gemini AI vision (~45s timeout) with automatic refund on failure
// 8. Return diagnosis matching exact client model format
app.post(
  '/diagnose',
  verifyAppCheck,
  verifyAuth,
  checkIpRateLimit,
  validateDiagnoseInputs,
  parseAndValidateImage,
  createDiagnoseHandler(getGeminiApiKey)
);

// POST /feedback
// 1. Verify App Check token
// 2. Verify Firebase Auth token
// 3. Check Per-IP rate limit
// 4. Check scan ownership and save feedback
app.post(
  '/feedback',
  verifyAppCheck,
  verifyAuth,
  checkIpRateLimit,
  handleFeedback
);

// Handle 404 for unknown routes
app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'not_found',
      message: `Endpoint ${req.method} ${req.originalUrl} does not exist.`,
    },
  });
});

// Centralized error handling middleware
app.use((err, req, res, next) => {
  safeLogger.error('Unhandled server error in Express pipeline', { message: err.message });
  
  // Handle payload too large from Express body-parser
  if (err.type === 'entity.too.large' || err.status === 413) {
    return res.status(400).json({
      error: {
        code: 'bad_image',
        message: 'Request payload exceeds maximum allowed size. Please upload a smaller image.',
      },
    });
  }

  res.status(500).json({
    error: {
      code: 'server_error',
      message: 'An internal server error occurred.',
    },
  });
});

// Export 2nd Generation Cloud Function
exports.api = onRequest(
  {
    region: limits.region,
    secrets: [geminiApiKeySecret],
    timeoutSeconds: limits.timeoutSeconds,
    memory: limits.memory,
    cors: true,
    maxInstances: limits.maxInstances,
  },
  app
);

// Scheduled Cleanup for Expired Rate Limit Documents (Runs daily)
exports.cleanupExpiredRateLimits = onSchedule(
  {
    schedule: 'every 24 hours',
    region: limits.region,
    timeoutSeconds: 120,
    memory: '256MiB',
  },
  async (event) => {
    const now = new Date();
    const db = admin.firestore();
    try {
      const expiredIps = await db
        .collection('ip_limits')
        .where('expireAt', '<=', now)
        .limit(500)
        .get();

      if (!expiredIps.empty) {
        const batch = db.batch();
        expiredIps.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        safeLogger.info(`Cleaned up ${expiredIps.size} expired IP limit records.`);
      }
    } catch (err) {
      safeLogger.error('Error during scheduled cleanup of rate limit docs', { message: err.message });
    }
  }
);
