const assert = require('assert');
const { getDiagnosisPrompt } = require('../prompts/diagnosis');
const { DiagnosisSchema, parseAndValidateDiagnosis } = require('../services/aiService');
const { detectImageMimeType, MAX_IMAGE_BYTES } = require('../middleware/imageParser');
const { sanitize } = require('../middleware/sanitizeLogs');

console.log('Running Crop Doctor Backend Unit Tests...\n');

// 1. Test Prompt Generation
console.log('Test 1: Diagnosis Prompt Generation');
const enPrompt = getDiagnosisPrompt({ crop: 'tomato', language: 'en' });
assert(enPrompt.includes('TARGET CROP: tomato'), 'English prompt should mention tomato');
assert(enPrompt.includes('severity'), 'Prompt should describe severity');

const hiPrompt = getDiagnosisPrompt({ crop: 'potato', language: 'hi' });
assert(hiPrompt.includes('देवनागरी लिपि'), 'Hindi prompt should include Hindi instructions');
console.log('  Passed: Prompt generation tests');

// 2. Test Zod Diagnosis Schema Validation
console.log('Test 2: Schema Validation');
const sampleValidJson = JSON.stringify({
  diseaseName: 'Early Blight',
  scientificName: 'Alternaria solani',
  severity: 'moderate',
  confidenceLevel: 'High',
  description: 'Brown concentric spots with target-board appearance on lower leaves.',
  immediateActions: ['Remove and destroy infected leaves', 'Avoid overhead watering'],
  organicTreatments: ['Spray neem oil solution (5ml/L)', 'Apply Trichoderma harzianum bio-fungicide'],
  chemicalTreatments: ['Mancozeb 75% WP @ 2g/L', 'Chlorothalonil @ 2g/L'],
  safetyNote: 'Wear gloves and face mask while spraying fungicides.',
  preventionTips: ['Ensure proper plant spacing for aeration', 'Rotate crops every 2-3 seasons']
});

const validated = parseAndValidateDiagnosis(sampleValidJson);
assert.strictEqual(validated.diseaseName, 'Early Blight');
assert.strictEqual(validated.severity, 'moderate');
assert.strictEqual(validated.immediateActions.length, 2);

// Test Markdown strip
const markdownWrappedJson = `\`\`\`json\n${sampleValidJson}\n\`\`\``;
const validatedMd = parseAndValidateDiagnosis(markdownWrappedJson);
assert.strictEqual(validatedMd.diseaseName, 'Early Blight');

// Test Schema Rejection on invalid data
assert.throws(() => {
  parseAndValidateDiagnosis(JSON.stringify({ diseaseName: 'Only Name' }));
}, /Diagnosis schema validation failed/);
console.log('  Passed: Schema validation tests');

// 3. Test Image Magic Bytes Validation
console.log('Test 3: Magic Bytes Image Detection');
const fakeJpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);
assert.strictEqual(detectImageMimeType(fakeJpeg), 'image/jpeg');

const fakePng = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]);
assert.strictEqual(detectImageMimeType(fakePng), 'image/png');

const fakePdf = Buffer.from('%PDF-1.4 sample file content');
assert.strictEqual(detectImageMimeType(fakePdf), null, 'Non-image buffer should return null');

assert.strictEqual(MAX_IMAGE_BYTES, 2 * 1024 * 1024, 'Max bytes must be 2MB');
console.log('  Passed: Magic bytes tests');

// 4. Test Log Sanitizer
console.log('Test 4: Sensitive Data Log Sanitization');
const dirtyLog = {
  user: 'uid123',
  apiKey: 'AIzaSyA_sample_google_api_key_1234567890',
  image: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...',
  nested: {
    token: 'Bearer eyJhbGciOi...',
    normalField: 'test'
  }
};

const sanitized = sanitize(dirtyLog);
assert.strictEqual(sanitized.apiKey, '[REDACTED_CREDENTIAL]');
assert.strictEqual(sanitized.image, '[REDACTED_IMAGE_PAYLOAD]');
assert.strictEqual(sanitized.nested.token, '[REDACTED_CREDENTIAL]');
assert.strictEqual(sanitized.nested.normalField, 'test');
console.log('  Passed: Log sanitizer tests');

console.log('\nAll 4 unit tests PASSED successfully!');
