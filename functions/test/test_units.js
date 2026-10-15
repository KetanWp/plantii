const assert = require('assert');
const { getDiagnosisPrompt } = require('../prompts/diagnosis');
const { DiagnosisSchema, parseAndValidateDiagnosis } = require('../services/aiService');
const { detectImageMimeType, MAX_IMAGE_BYTES } = require('../middleware/imageParser');
const { sanitize } = require('../middleware/sanitizeLogs');

console.log('Running Crop Doctor Backend Unit Tests...\n');

// 1. Test Prompt Generation
console.log('Test 1: Diagnosis Prompt Generation');
const autoPrompt = getDiagnosisPrompt({ language: 'en' });
assert(autoPrompt.includes('AUTOMATIC CROP IDENTIFICATION'), 'English prompt should mention automatic crop identification');
assert(autoPrompt.includes('spokenSummary'), 'English prompt should mention spokenSummary');
assert(autoPrompt.includes('cropConfidence'), 'English prompt should mention cropConfidence');

const hintPrompt = getDiagnosisPrompt({ cropHint: 'Tomato', language: 'en' });
assert(hintPrompt.includes('FARMER CONFIRMED CROP: "Tomato"'), 'Prompt with cropHint should include confirmed crop');

const hiPrompt = getDiagnosisPrompt({ language: 'hi' });
assert(hiPrompt.includes('देवनागरी लिपि'), 'Hindi prompt should include Hindi instructions');
assert(hiPrompt.includes('spokenSummary'), 'Prompt should mention spokenSummary');
console.log('  Passed: Prompt generation tests');

// 2. Test Zod Diagnosis Schema Validation
console.log('Test 2: Schema Validation (diseased, healthy, not_a_plant, poor_photo)');

// 2a. Diseased valid case
const diseasedJson = JSON.stringify({
  status: 'diseased',
  detectedCrop: 'Tomato',
  cropConfidence: 'very_likely',
  diseaseName: 'Early Blight',
  scientificName: 'Alternaria solani',
  severity: 'moderate',
  confidence: 'very_likely',
  description: 'Brown concentric spots with target-board appearance on lower leaves.',
  immediateActions: ['Remove and destroy infected leaves', 'Avoid overhead watering'],
  organicTreatments: ['Spray neem oil solution (5ml/L)', 'Apply Trichoderma harzianum bio-fungicide'],
  chemicalTreatments: ['Mancozeb 75% WP @ 2g/L', 'Chlorothalonil @ 2g/L'],
  safetyNote: 'Wear gloves and face mask while spraying fungicides.',
  prevention: ['Ensure proper plant spacing for aeration', 'Rotate crops every 2-3 seasons'],
  photoQuality: 'good',
  possibleCauses: ['Fungal spores surviving in soil', 'High relative humidity and warm temperatures'],
  spokenSummary: 'टमाटर के पौधे में अगेती झुलसा रोग लगा है। यह मध्यम रूप से गंभीर है। तुरंत प्रभावित पत्तों को तोड़कर नष्ट कर दें। छिड़काव करते समय मास्क और दस्ताने अवश्य पहनें।'
});

const validatedDiseased = parseAndValidateDiagnosis(diseasedJson);
assert.strictEqual(validatedDiseased.status, 'diseased');
assert.strictEqual(validatedDiseased.detectedCrop, 'Tomato');
assert.strictEqual(validatedDiseased.cropConfidence, 'very_likely');
assert.strictEqual(validatedDiseased.diseaseName, 'Early Blight');
assert.strictEqual(validatedDiseased.severity, 'moderate');
assert.strictEqual(validatedDiseased.confidence, 'very_likely');
assert.strictEqual(validatedDiseased.confidenceLevel, 'very_likely');
assert.strictEqual(validatedDiseased.immediateActions.length, 2);
assert.strictEqual(validatedDiseased.organicTreatments.length, 2);
assert.strictEqual(validatedDiseased.chemicalTreatments.length, 2);
assert(validatedDiseased.spokenSummary.length > 10, 'Spoken summary should be present');

// 2b. Healthy valid case (empty treatments and blank diseaseName are valid)
const healthyJson = JSON.stringify({
  status: 'healthy',
  detectedCrop: 'Wheat',
  cropConfidence: 'likely',
  diseaseName: '',
  scientificName: '',
  severity: 'none',
  confidence: 'very_likely',
  description: 'Plant foliage appears vibrant, green, and healthy with no signs of disease or deficiency.',
  immediateActions: [],
  organicTreatments: [],
  chemicalTreatments: [],
  safetyNote: '',
  prevention: [],
  photoQuality: 'good',
  possibleCauses: [],
  spokenSummary: 'आपकी गेहूं की फसल पूरी तरह स्वस्थ है। उचित समय पर सिंचाई करते रहें।'
});
const validatedHealthy = parseAndValidateDiagnosis(healthyJson);
assert.strictEqual(validatedHealthy.status, 'healthy');
assert.strictEqual(validatedHealthy.detectedCrop, 'Wheat');
assert.strictEqual(validatedHealthy.cropConfidence, 'likely');
assert.strictEqual(validatedHealthy.confidence, 'very_likely');
assert.strictEqual(validatedHealthy.diseaseName, '');
assert.strictEqual(validatedHealthy.organicTreatments.length, 0);

// 2c. Not a plant valid case
const notPlantJson = JSON.stringify({
  status: 'not_a_plant',
  detectedCrop: 'None',
  cropConfidence: 'very_likely',
  diseaseName: '',
  scientificName: '',
  confidence: 'very_likely',
  description: 'This photo does not contain a plant or crop leaf. Please photograph a crop leaf.',
  immediateActions: [],
  organicTreatments: [],
  chemicalTreatments: [],
  safetyNote: '',
  prevention: [],
  photoQuality: 'poor',
  possibleCauses: [],
  spokenSummary: 'यह फोटो किसी पौधे या पत्ती की नहीं है।'
});
const validatedNotPlant = parseAndValidateDiagnosis(notPlantJson);
assert.strictEqual(validatedNotPlant.status, 'not_a_plant');
assert.strictEqual(validatedNotPlant.detectedCrop, 'None');
assert.strictEqual(validatedNotPlant.confidence, 'very_likely');

// 2d. Poor photo valid case
const poorPhotoJson = JSON.stringify({
  status: 'poor_photo',
  detectedCrop: 'Unknown / Unclear',
  cropConfidence: 'possible',
  diseaseName: '',
  scientificName: '',
  confidence: 'very_likely',
  description: 'The leaf photo is too blurry and out of focus. Please retake a clear close-up.',
  immediateActions: [],
  organicTreatments: [],
  chemicalTreatments: [],
  safetyNote: '',
  prevention: [],
  photoQuality: 'poor',
  possibleCauses: [],
  spokenSummary: 'फोटो बहुत धुंधली है। कृपया पास से साफ फोटो दोबारा लें।'
});
const validatedPoorPhoto = parseAndValidateDiagnosis(poorPhotoJson);
assert.strictEqual(validatedPoorPhoto.status, 'poor_photo');
assert.strictEqual(validatedPoorPhoto.detectedCrop, 'Unknown / Unclear');
assert.strictEqual(validatedPoorPhoto.cropConfidence, 'possible');
assert.strictEqual(validatedPoorPhoto.photoQuality, 'poor');

// 2d-2. Test default fallback if detectedCrop is omitted
const omittedCropJson = JSON.stringify({
  status: 'healthy',
  diseaseName: '',
  scientificName: '',
  confidence: 'likely',
  description: 'Healthy leaf without detectedCrop specified.'
});
const validatedOmitted = parseAndValidateDiagnosis(omittedCropJson);
assert.strictEqual(validatedOmitted.detectedCrop, 'Unknown Plant', 'Should default to Unknown Plant if omitted');
assert.strictEqual(validatedOmitted.cropConfidence, 'likely', 'Should default to likely if omitted');
assert(validatedOmitted.spokenSummary.length > 0, 'Should generate fallback spokenSummary');

// 2e. Markdown wrapped JSON strip
const markdownWrappedJson = `\`\`\`json\n${diseasedJson}\n\`\`\``;
const validatedMd = parseAndValidateDiagnosis(markdownWrappedJson);
assert.strictEqual(validatedMd.diseaseName, 'Early Blight');

// 2f. Diseased schema rejection when treatments or diseaseName are missing
assert.throws(() => {
  parseAndValidateDiagnosis(JSON.stringify({
    status: 'diseased',
    diseaseName: 'Early Blight',
    severity: 'mild',
    confidence: 'very_likely',
    description: 'Leaf spots',
    immediateActions: [],
    organicTreatments: [], // Invalid for diseased!
    chemicalTreatments: [],
  }));
}, /Diagnosis schema validation failed/);

// 2g. Rejection on invalid status or invalid confidence
assert.throws(() => {
  parseAndValidateDiagnosis(JSON.stringify({
    status: 'unknown_alien',
    confidence: 'very_likely',
    description: 'test'
  }));
}, /Diagnosis schema validation failed/);

assert.throws(() => {
  parseAndValidateDiagnosis(JSON.stringify({
    status: 'healthy',
    confidence: 'unsupported_confidence_word',
    description: 'test'
  }));
}, /Diagnosis schema validation failed/);

console.log('  Passed: All 4 status schema validation tests (diseased, healthy, not_a_plant, poor_photo)');

// 3. Test Image Magic Bytes Validation
console.log('Test 3: Magic Bytes Image Detection');
const fakeJpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);
assert.strictEqual(detectImageMimeType(fakeJpeg), 'image/jpeg');

const fakePng = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]);
assert.strictEqual(detectImageMimeType(fakePng), 'image/png');

const fakePdf = Buffer.from('%PDF-1.4 sample file content');
assert.strictEqual(detectImageMimeType(fakePdf), null, 'Non-image buffer should return null');

assert.strictEqual(MAX_IMAGE_BYTES, 1.5 * 1024 * 1024, 'Max bytes must be 1.5MB');
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
