/**
 * Firebase Cloud Functions (2nd gen) Backend for Crop Doctor
 *
 * Implements Express REST API with endpoints:
 * - POST /diagnose (AI Vision diagnosis with rate limiting and timeout)
 * - POST /feedback (User feedback with ownership check)
 * - GET  /health   (Liveness probe)
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const express = require('express');
const cors = require('cors');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

// Import middlewares
const { verifyAuth } = require('./middleware/auth');
const { checkDailyRateLimit } = require('./middleware/rateLimiter');
const { parseAndValidateImage } = require('./middleware/imageParser');
const { sanitizeRequestLogging, safeLogger } = require('./middleware/sanitizeLogs');

// Import route handlers
const { createDiagnoseHandler } = require('./routes/diagnose');
const { handleFeedback } = require('./routes/feedback');

// Define Firebase Secret for AI API key (never hardcoded in code)
const aiApiKeySecret = defineSecret('AI_API_KEY');

// Helper to retrieve the secret safely in production or local emulator
function getAiApiKey() {
  try {
    return aiApiKeySecret.value() || process.env.AI_API_KEY || process.env.GEMINI_API_KEY || '';
  } catch (err) {
    // In emulator or offline environments where defineSecret is not bound
    return process.env.AI_API_KEY || process.env.GEMINI_API_KEY || '';
  }
}

// Create Express application
const app = express();

// Apply global middlewares
app.use(cors({ origin: true }));
app.use(sanitizeRequestLogging);

// Parse JSON bodies up to 10MB to accommodate base64 image strings
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'Crop Doctor Backend (2nd gen)',
    timestamp: new Date().toISOString(),
  });
});

// POST /diagnose
// 1. Verify Firebase Auth token
// 2. Parse & validate image (<= 2MB, jpeg/png)
// 3. Verify & increment daily rate limit (<= 10 scans/day)
// 4. Run AI vision with schema validation & 60s timeout handling
app.post(
  '/diagnose',
  verifyAuth,
  parseAndValidateImage,
  checkDailyRateLimit,
  createDiagnoseHandler(getAiApiKey)
);

// POST /feedback
// 1. Verify Firebase Auth token
// 2. Check scan ownership and save feedback
app.post(
  '/feedback',
  verifyAuth,
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
  safeLogger.error('Unhandled server error in Express pipeline', { message: err.message, stack: err.stack });
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
    secrets: [aiApiKeySecret],
    timeoutSeconds: 60,
    memory: '512MiB',
    cors: true,
    maxInstances: 10,
  },
  app
);
