/**
 * AI Vision Service using Google Gemini
 *
 * Calls Vision AI with leaf image and custom prompt template.
 * Forces JSON output, validates against Zod schema, retries once on invalid format.
 * Never logs images or API keys.
 */

const { GoogleGenerativeAI } = require('@google/generative-ai');
const { z } = require('zod');
const { getDiagnosisPrompt } = require('../prompts/diagnosis');
const { safeLogger } = require('../middleware/sanitizeLogs');

/**
 * Strict schema matching the Crop Doctor client-side Diagnosis model
 */
const DiagnosisSchema = z.object({
  diseaseName: z.string().min(1, 'diseaseName is required'),
  scientificName: z.string().default('N/A'),
  severity: z.enum(['mild', 'moderate', 'severe']).catch('moderate'),
  confidenceLevel: z.string().min(1, 'confidenceLevel is required'),
  description: z.string().min(1, 'description is required'),
  immediateActions: z.array(z.string()).min(1, 'At least 1 immediate action required'),
  organicTreatments: z.array(z.string()).min(1, 'At least 1 organic treatment required'),
  chemicalTreatments: z.array(z.string()).min(1, 'At least 1 chemical treatment required'),
  safetyNote: z.string().min(1, 'safetyNote is required'),
  preventionTips: z.array(z.string()).min(1, 'At least 1 prevention tip required'),
});

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

  const validated = DiagnosisSchema.safeParse(parsed);
  if (!validated.success) {
    const errorDetails = validated.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join(', ');
    throw new Error(`Diagnosis schema validation failed: ${errorDetails}`);
  }

  return validated.data;
}

/**
 * Analyzes crop leaf image using Gemini Vision API with 1 retry on invalid format
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
    throw new Error('AI API Key is missing. Please configure AI_API_KEY via Firebase secrets.');
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  // Use gemini-1.5-flash for rapid, cost-effective vision reasoning
  const model = genAI.getGenerativeModel({
    model: 'gemini-1.5-flash',
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.2,
    },
  });

  const basePrompt = getDiagnosisPrompt({ crop, language });
  const imagePart = {
    inlineData: {
      data: imageBuffer.toString('base64'),
      mimeType,
    },
  };

  // Attempt 1: Primary diagnosis call
  try {
    safeLogger.info(`Initiating AI vision analysis for crop: "${crop}", language: "${language}"`);
    const result = await model.generateContent([basePrompt, imagePart]);
    const responseText = result.response.text();
    return parseAndValidateDiagnosis(responseText);
  } catch (firstError) {
    safeLogger.warn('First AI diagnosis attempt failed or returned invalid JSON. Retrying once...', {
      errorMessage: firstError.message,
    });

    // Attempt 2: Retry once with corrective strict instruction
    try {
      const correctivePrompt = `${basePrompt}

CRITICAL RETRY INSTRUCTION:
Your previous response failed JSON schema validation.
You MUST output valid, raw JSON only matching the schema exactly.
No explanations, no markdown tags. Ensure all required fields exist and severity is strictly 'mild', 'moderate', or 'severe'.`;

      const retryResult = await model.generateContent([correctivePrompt, imagePart]);
      const retryText = retryResult.response.text();
      const validated = parseAndValidateDiagnosis(retryText);
      safeLogger.info('AI vision analysis succeeded on retry');
      return validated;
    } catch (retryError) {
      safeLogger.error('AI vision analysis failed after retry', {
        firstError: firstError.message,
        retryError: retryError.message,
      });

      const failure = new Error('AI analysis failed to produce a valid diagnosis format after retry.');
      failure.code = 'ai_failed';
      throw failure;
    }
  }
}

module.exports = {
  analyzeCropLeaf,
  DiagnosisSchema,
  parseAndValidateDiagnosis,
};
