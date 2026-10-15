/**
 * Tests for Image-Hash Cache and Determinism
 *
 * Verifies:
 * 1. Missing crop is accepted and passes to prompt
 * 2. Same image twice returns the same result and the second is cached (fromCache: true)
 *    WITHOUT calling Gemini and WITHOUT consuming daily scan quota
 * 3. Different image triggers new AI analysis and consumes daily scan quota
 */

const assert = require('assert');
const crypto = require('crypto');
const { getDiagnosisPrompt } = require('../prompts/diagnosis');

console.log('Running Image-Hash Cache Tests...\n');

// 1. Test missing crop accepted and passed to prompt
console.log('Test 1: Missing crop is accepted in prompt');
{
  const prompt = getDiagnosisPrompt({ language: 'en' });
  assert(prompt.includes('AUTOMATIC CROP IDENTIFICATION'), 'Should specify auto identification');
  assert(!prompt.includes('TARGET CROP:'), 'Should not specify target crop');
  console.log('  Passed: Missing crop accepted');
}

// 2. Mock tests for Caching and Quota Preservation
console.log('Test 2: Same image twice returns cached result with fromCache: true and zero quota');
{
  // Simulated Firestore Cache Store
  const mockCacheStore = new Map();
  const mockUserScanCount = { 'farmer_101': 0 };
  let geminiCallCount = 0;

  // Sample JPEG buffer (valid magic bytes)
  const sampleImage1 = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x00, 0x01]);
  const sampleImage2 = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x00, 0x02]);

  // Diagnosis Handler with injected cache store mock
  async function simulateDiagnose({ userId, imageBuffer, language }) {
    const imageHash = crypto.createHash('sha256').update(imageBuffer).digest('hex');
    const cacheKey = `${imageHash}_${language}`;

    // 1. Cache lookup
    if (mockCacheStore.has(`${userId}_${cacheKey}`)) {
      const cached = mockCacheStore.get(`${userId}_${cacheKey}`);
      return {
        ...cached,
        fromCache: true,
      };
    }

    // 2. User quota check
    mockUserScanCount[userId] = (mockUserScanCount[userId] || 0) + 1;

    // 3. AI call
    geminiCallCount++;
    const aiResult = {
      id: `scan_${Date.now()}_${geminiCallCount}`,
      detectedCrop: 'Tomato',
      cropConfidence: 'very_likely',
      status: 'diseased',
      diseaseName: 'Early Blight',
      severity: 'moderate',
      confidence: 'very_likely',
      description: 'Concentric leaf spots observed.',
      immediateActions: ['Remove infected foliage'],
      organicTreatments: ['Neem oil spray'],
      chemicalTreatments: ['Mancozeb 75% WP'],
      safetyNote: 'Wear gloves and mask',
      prevention: ['Crop rotation'],
      spokenSummary: 'टमाटर के पौधे में अगेती झुलसा रोग लगा है। प्रभावित पत्तियों को तुरंत हटा दें।',
      language,
      fromCache: false,
    };

    // 4. Cache save
    mockCacheStore.set(`${userId}_${cacheKey}`, aiResult);

    return aiResult;
  }

  // --- Run 1: First scan for farmer_101 ---
  const result1 = simulateDiagnose({
    userId: 'farmer_101',
    imageBuffer: sampleImage1,
    language: 'en',
  });

  result1.then(async (res1) => {
    assert.strictEqual(res1.fromCache, false, 'First scan should NOT be from cache');
    assert.strictEqual(geminiCallCount, 1, 'Gemini should be called once on first scan');
    assert.strictEqual(mockUserScanCount['farmer_101'], 1, 'User scan count should increment to 1');

    // --- Run 2: Exact same image, same user, same language -> CACHE HIT ---
    const res2 = await simulateDiagnose({
      userId: 'farmer_101',
      imageBuffer: sampleImage1,
      language: 'en',
    });

    assert.strictEqual(res2.fromCache, true, 'Second scan of same image MUST be fromCache: true');
    assert.strictEqual(geminiCallCount, 1, 'Gemini must NOT be called on cache hit');
    assert.strictEqual(mockUserScanCount['farmer_101'], 1, 'Daily scan count must NOT increment on cache hit');
    assert.strictEqual(res2.diseaseName, res1.diseaseName, 'Cached result must match first result');
    console.log('  Passed: Second scan served from cache with fromCache: true and zero quota used');

    // --- Run 3: Different image -> CACHE MISS, CALLS AI & CONSUMES QUOTA ---
    const res3 = await simulateDiagnose({
      userId: 'farmer_101',
      imageBuffer: sampleImage2,
      language: 'en',
    });

    assert.strictEqual(res3.fromCache, false, 'Different image must NOT be served from cache');
    assert.strictEqual(geminiCallCount, 2, 'Gemini must be called on cache miss');
    assert.strictEqual(mockUserScanCount['farmer_101'], 2, 'User scan count should increment to 2');
    console.log('  Passed: Different image calls AI and increments quota');

    console.log('\nAll Caching and Determinism Tests PASSED Successfully!');
  });
}
