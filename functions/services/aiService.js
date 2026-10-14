/**
 * AI Vision Service using Google Gemini via official @google/genai SDK
 *
 * Calls Gemini Vision AI with leaf image and custom prompt template.
 * Forces structured JSON output matching Diagnosis model schema.
 * Enforces status ("diseased", "healthy", "not_a_plant", "poor_photo").
 * Refines schema so treatments, diseaseName, causes are only required when status is "diseased".
 * Confidence enum: "very_likely", "likely", "possible".
 * No silent .catch() defaults; invalid values trigger single retry, then ai_failed.
 * Supports primary & fallback models list from limits.js.
 * NEVER returns mock, invented, or default disease results.
 * NEVER logs images, API keys, or raw full AI responses.
 * Enforces ~45-second timeout budget across calls.
 */

const { GoogleGenAI, Type } = require('@google/genai');
const { z } = require('zod');
const limits = require('../config/limits');
const { getDiagnosisPrompt } = require('../prompts/diagnosis');
const { safeLogger } = require('../middleware/sanitizeLogs');

/**
 * Base schema matching the Diagnosis model:
 * status: "diseased" | "healthy" | "not_a_plant" | "poor_photo"
 * confidence: "very_likely" | "likely" | "possible"
 */
const BaseDiagnosisSchema = z.object({
  status: z.enum(['diseased', 'healthy', 'not_a_plant', 'poor_photo']),
  diseaseName: z.string().default(''),
  scientificName: z.string().default(''),
  severity: z.enum(['mild', 'moderate', 'severe']).optional().or(z.literal('')).or(z.literal('none')),
  confidence: z.enum(['very_likely', 'likely', 'possible']),
  description: z.string().min(1, 'description is required'),
  immediateActions: z.array(z.string()).default([]),
  organicTreatments: z.array(z.string()).default([]),
  chemicalTreatments: z.array(z.string()).default([]),
  safetyNote: z.string().default(''),
  prevention: z.array(z.string()).default([]),
  photoQuality: z.enum(['good', 'poor', 'unclear']).default('good'),
  possibleCauses: z.array(z.string()).default([]),
});

/**
 * Zod refinement:
 * When status is "diseased", diseaseName, severity, treatments, immediateActions,
 * possibleCauses, and prevention are strictly required with at least 1 item / non-empty.
 * When status is "healthy", "not_a_plant", or "poor_photo", they are valid as empty/blank.
 */
const DiagnosisSchema = BaseDiagnosisSchema.superRefine((data, ctx) => {
  if (data.status === 'diseased') {
    if (!data.diseaseName || data.diseaseName.trim().length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'diseaseName is required when status is diseased',
        path: ['diseaseName'],
      });
    }
    if (!data.severity || !['mild', 'moderate', 'severe'].includes(data.severity)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'severity must be mild, moderate, or severe when status is diseased',
        path: ['severity'],
      });
    }
    if (!Array.isArray(data.immediateActions) || data.immediateActions.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'At least 1 immediate action is required when status is diseased',
        path: ['immediateActions'],
      });
    }
    if (!Array.isArray(data.organicTreatments) || data.organicTreatments.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'At least 1 organic treatment is required when status is diseased',
        path: ['organicTreatments'],
      });
    }
    if (!Array.isArray(data.chemicalTreatments) || data.chemicalTreatments.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'At least 1 chemical treatment is required when status is diseased',
        path: ['chemicalTreatments'],
      });
    }
    if (!data.safetyNote || data.safetyNote.trim().length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'safetyNote is required when status is diseased',
        path: ['safetyNote'],
      });
    }
    if (!Array.isArray(data.prevention) || data.prevention.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'At least 1 prevention tip is required when status is diseased',
        path: ['prevention'],
      });
    }
    if (!Array.isArray(data.possibleCauses) || data.possibleCauses.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'At least 1 possible cause is required when status is diseased',
        path: ['possibleCauses'],
      });
    }
  }
});

/**
 * Gemini response schema definition for structured output
 */
const geminiResponseSchema = {
  type: Type.OBJECT,
  properties: {
    status: {
      type: Type.STRING,
      enum: ['diseased', 'healthy', 'not_a_plant', 'poor_photo'],
    },
    diseaseName: { type: Type.STRING },
    scientificName: { type: Type.STRING },
    severity: {
      type: Type.STRING,
      enum: ['mild', 'moderate', 'severe', 'none'],
    },
    confidence: {
      type: Type.STRING,
      enum: ['very_likely', 'likely', 'possible'],
    },
    description: { type: Type.STRING },
    immediateActions: { type: Type.ARRAY, items: { type: Type.STRING } },
    organicTreatments: { type: Type.ARRAY, items: { type: Type.STRING } },
    chemicalTreatments: { type: Type.ARRAY, items: { type: Type.STRING } },
    safetyNote: { type: Type.STRING },
    prevention: { type: Type.ARRAY, items: { type: Type.STRING } },
    photoQuality: {
      type: Type.STRING,
      enum: ['good', 'poor', 'unclear'],
    },
    possibleCauses: { type: Type.ARRAY, items: { type: Type.STRING } },
  },
  required: [
    'status',
    'confidence',
    'description',
  ],
};

/**
 * Strips markdown code fences (e.g. ```json ... ```) if present
 * @param {string} raw
 * @returns {string}
 */
function cleanJsonString(raw) {
  if (!raw || typeof raw !== 'string') return '';
  let cleaned = raw.trim();

  // Strip leading code fence
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.substring(7);
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.substring(3);
  }

  // Strip trailing code fence
  if (cleaned.endsWith('```')) {
    cleaned = cleaned.substring(0, cleaned.length - 3);
  }

  return cleaned.trim();
}

/**
 * Parses and validates raw AI text against the DiagnosisSchema
 * Also sets backward-compatible aliases (confidenceLevel, preventionTips) for Flutter client
 * @param {string} rawText
 * @returns {Object} validated diagnosis data
 */
function parseAndValidateDiagnosis(rawText) {
  const cleaned = cleanJsonString(rawText);
  let parsed;
  try {
    parsed = JSON.parse(cleaned);
  } catch (err) {
    throw new Error(`Invalid JSON syntax from AI: ${err.message}`);
  }

  // Normalize aliases if model used synonyms
  if (!parsed.confidence && parsed.confidenceLevel) {
    parsed.confidence = parsed.confidenceLevel;
  }
  if (!parsed.prevention && parsed.preventionTips) {
    parsed.prevention = parsed.preventionTips;
  }

  // Normalize confidence to enum: "very_likely", "likely", "possible"
  if (parsed.confidence) {
    const rawConf = String(parsed.confidence).toLowerCase().trim();
    if (rawConf === 'high' || rawConf.includes('very') || rawConf === 'very_likely' || rawConf.includes('उच्च')) {
      parsed.confidence = 'very_likely';
    } else if (rawConf === 'medium' || rawConf === 'likely' || rawConf.includes('मध्यम')) {
      parsed.confidence = 'likely';
    } else if (rawConf === 'low' || rawConf === 'possible' || rawConf.includes('कम')) {
      parsed.confidence = 'possible';
    }
  }

  // Normalize severity if empty or "none"
  if (parsed.severity === 'none' || parsed.severity === undefined) {
    parsed.severity = '';
  }

  // Default empty arrays and strings if not provided
  parsed.immediateActions = parsed.immediateActions || [];
  parsed.organicTreatments = parsed.organicTreatments || [];
  parsed.chemicalTreatments = parsed.chemicalTreatments || [];
  parsed.prevention = parsed.prevention || [];
  parsed.possibleCauses = parsed.possibleCauses || [];
  parsed.diseaseName = parsed.diseaseName || '';
  parsed.scientificName = parsed.scientificName || '';
  parsed.safetyNote = parsed.safetyNote || '';

  const validated = DiagnosisSchema.safeParse(parsed);
  if (!validated.success) {
    const errorDetails = validated.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join(', ');
    throw new Error(`Diagnosis schema validation failed: ${errorDetails}`);
  }

  // Return validated data with client-compatible alias mappings
  return {
    ...validated.data,
    confidenceLevel: validated.data.confidence,
    preventionTips: validated.data.prevention,
  };
}

/**
 * Helper to run a promise with a timeout
 * @param {Promise} promise
 * @param {number} ms
 * @param {string} message
 * @returns {Promise}
 */
function withTimeout(promise, ms, message = 'AI call timed out') {
  let timer;
  const timeoutPromise = new Promise((_, reject) => {
    timer = setTimeout(() => {
      const err = new Error(message);
      err.code = 'timeout';
      err.status = 504;
      reject(err);
    }, ms);
  });
  return Promise.race([promise, timeoutPromise]).finally(() => clearTimeout(timer));
}

/**
 * Detects if an error is due to model overload or temporary unavailability (503 / 429)
 * @param {Error} err
 * @returns {boolean}
 */
function isOverloadError(err) {
  if (!err) return false;
  const status = err.status || 0;
  const msg = (err.message || '').toLowerCase();
  return (
    status === 503 ||
    status === 429 ||
    msg.includes('unavailable') ||
    msg.includes('high demand') ||
    msg.includes('resource_exhausted') ||
    msg.includes('overload') ||
    msg.includes('capacity')
  );
}

/**
 * Classifies Gemini error into standard application error codes
 * Never exposes API keys or internal stack traces
 * @param {Error} error
 * @returns {{ code: string, status: number, message: string }}
 */
function classifyGeminiError(error) {
  if (error.code === 'timeout' || error.status === 504) {
    return {
      code: 'timeout',
      status: 504,
      message: 'The diagnosis request timed out after 45 seconds. Please try again.',
    };
  }

  const msg = (error.message || '').toLowerCase();
  const status = error.status || 0;

  // Quota exceeded / Rate limited
  if (status === 429 || msg.includes('quota') || msg.includes('resource_exhausted') || msg.includes('rate limit')) {
    return {
      code: 'quota_exceeded',
      status: 503,
      message: 'AI diagnosis service is currently at capacity. Please try again shortly.',
    };
  }

  // 503 Service Unavailable / Overload
  if (status === 503 || msg.includes('unavailable') || msg.includes('high demand')) {
    return {
      code: 'service_busy',
      status: 503,
      message: 'AI diagnosis service is currently experiencing high demand. Please try again in a moment.',
    };
  }

  // Safety filter block
  if (msg.includes('safety') || msg.includes('blocked') || msg.includes('finishreason: safety') || msg.includes('harm')) {
    return {
      code: 'safety_block',
      status: 400,
      message: 'The photo could not be processed due to safety guidelines. Please take a clear photo of the plant leaf.',
    };
  }

  // Bad API Key / Authentication
  if (
    msg.includes('api_key_invalid') ||
    msg.includes('api key not valid') ||
    status === 401 ||
    status === 403 ||
    msg.includes('unauthenticated') ||
    msg.includes('permission_denied')
  ) {
    return {
      code: 'ai_auth_error',
      status: 500,
      message: 'AI service configuration error. Please contact administrator.',
    };
  }

  // Network errors
  if (
    msg.includes('econnreset') ||
    msg.includes('enotfound') ||
    msg.includes('etimedout') ||
    msg.includes('fetch failed') ||
    msg.includes('network')
  ) {
    return {
      code: 'network_error',
      status: 502,
      message: 'Network communication with AI service failed. Please check connection and retry.',
    };
  }

  return {
    code: error.code || 'ai_failed',
    status: 502,
    message: 'Failed to analyze crop leaf. Please retry with a clearer photo.',
  };
}

/**
 * Analyzes crop leaf image using Gemini Vision API with model fallback and 1 retry on invalid format
 *
 * @param {Object} options
 * @param {string} options.apiKey - Gemini AI API Key from Firebase Secret
 * @param {Buffer} options.imageBuffer - Raw JPEG/PNG image buffer
 * @param {string} options.mimeType - 'image/jpeg' or 'image/png'
 * @param {string} [options.crop] - Crop name
 * @param {string} [options.language] - 'hi' or 'en'
 * @returns {Promise<Object>} Validated diagnosis object
 */
async function analyzeCropLeaf({ apiKey, imageBuffer, mimeType, crop = 'plant', language = 'en' }) {
  if (!apiKey) {
    const keyErr = new Error('AI API Key is missing. Please configure GEMINI_API_KEY via Firebase secrets.');
    keyErr.code = 'ai_auth_error';
    keyErr.status = 500;
    throw keyErr;
  }

  // Initialize official @google/genai client
  const ai = new GoogleGenAI({ apiKey });

  // Configured ordered models list (primary and fallback)
  const models = Array.isArray(limits.geminiModels) && limits.geminiModels.length > 0
    ? limits.geminiModels
    : [limits.geminiModel || 'gemini-3.5-flash'];

  let modelIndex = 0;
  let activeModel = models[modelIndex];

  const basePrompt = getDiagnosisPrompt({ crop, language });
  const contents = [
    { text: basePrompt },
    {
      inlineData: {
        mimeType,
        data: imageBuffer.toString('base64'),
      },
    },
  ];

  const config = {
    temperature: 0.2,
    responseMimeType: 'application/json',
    responseSchema: geminiResponseSchema,
  };

  const startTime = Date.now();
  const overallTimeoutMs = limits.geminiTimeoutMs || 45000;

  function getRemainingTimeout() {
    const elapsed = Date.now() - startTime;
    return Math.max(overallTimeoutMs - elapsed, 2000);
  }

  // Attempt 1: Call with primary model (or fallback if primary is overloaded)
  try {
    safeLogger.info('Initiating Gemini vision analysis', {
      crop,
      language,
      model: activeModel,
    });

    let response;
    try {
      response = await withTimeout(
        ai.models.generateContent({
          model: activeModel,
          contents,
          config,
        }),
        getRemainingTimeout(),
        `Gemini Vision call timed out after ${overallTimeoutMs}ms`
      );
    } catch (primaryErr) {
      // If primary model experienced 503/overload and a fallback is configured, switch to fallback model
      if (isOverloadError(primaryErr) && modelIndex + 1 < models.length) {
        modelIndex++;
        activeModel = models[modelIndex];
        safeLogger.warn('Primary Gemini model overloaded / unavailable. Trying fallback model...', {
          previousModel: models[modelIndex - 1],
          fallbackModel: activeModel,
          remainingTimeoutMs: getRemainingTimeout(),
        });

        response = await withTimeout(
          ai.models.generateContent({
            model: activeModel,
            contents,
            config,
          }),
          getRemainingTimeout(),
          `Gemini Vision call timed out after ${overallTimeoutMs}ms`
        );
      } else {
        throw primaryErr;
      }
    }

    const responseText = response.text;
    if (!responseText) {
      throw new Error('Gemini returned empty response text');
    }

    return parseAndValidateDiagnosis(responseText);
  } catch (firstError) {
    if (firstError.code === 'timeout') {
      safeLogger.warn(`AI diagnosis attempt timed out after ${overallTimeoutMs}ms`);
      const classified = classifyGeminiError(firstError);
      const err = new Error(classified.message);
      err.code = classified.code;
      err.status = classified.status;
      throw err;
    }

    safeLogger.warn('First AI diagnosis attempt failed or returned invalid format. Retrying once...', {
      model: activeModel,
      errorType: firstError.name,
      errorMessage: firstError.message,
    });

    // Check if sufficient time remains for retry
    const remainingForRetry = getRemainingTimeout();
    if (remainingForRetry < 3000) {
      safeLogger.warn(`Insufficient time remaining for retry (${remainingForRetry}ms)`);
      const timeoutErr = new Error(`Gemini Vision call timed out after ${overallTimeoutMs}ms`);
      timeoutErr.code = 'timeout';
      timeoutErr.status = 504;
      throw timeoutErr;
    }

    // Attempt 2: Retry once with corrective strict instruction on active model
    try {
      const correctivePrompt = `${basePrompt}

CRITICAL RETRY INSTRUCTION:
Your previous response failed validation.
You MUST output valid, raw JSON only matching the schema exactly.
status must be strictly one of: "diseased", "healthy", "not_a_plant", "poor_photo".
confidence must be strictly one of: "very_likely", "likely", "possible".
If status is NOT "diseased", diseaseName, scientificName, treatments, actions, causes, and prevention MUST be empty.
If status is "diseased", diseaseName and all treatment/action/prevention/causes arrays MUST have at least 1 valid item.
No markdown fences, no extra text.`;

      const retryContents = [
        { text: correctivePrompt },
        {
          inlineData: {
            mimeType,
            data: imageBuffer.toString('base64'),
          },
        },
      ];

      const retryResponse = await withTimeout(
        ai.models.generateContent({
          model: activeModel,
          contents: retryContents,
          config,
        }),
        remainingForRetry,
        `Gemini Vision retry call timed out after ${overallTimeoutMs}ms`
      );

      const retryText = retryResponse.text;
      if (!retryText) {
        throw new Error('Gemini returned empty response text on retry');
      }

      const validated = parseAndValidateDiagnosis(retryText);
      safeLogger.info('Gemini vision analysis succeeded on retry');
      return validated;
    } catch (retryError) {
      const classified = classifyGeminiError(retryError);
      safeLogger.error('Gemini vision analysis failed after retry', {
        model: activeModel,
        classifiedCode: classified.code,
        status: classified.status,
      });

      const failure = new Error(classified.message);
      failure.code = classified.code;
      failure.status = classified.status;
      throw failure;
    }
  }
}

module.exports = {
  analyzeCropLeaf,
  BaseDiagnosisSchema,
  DiagnosisSchema,
  parseAndValidateDiagnosis,
  classifyGeminiError,
  cleanJsonString,
  withTimeout,
  isOverloadError,
  geminiResponseSchema,
};
