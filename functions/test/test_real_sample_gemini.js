/**
 * Test Script: Send Real Sample Leaf Image to /diagnose Endpoint
 *
 * Usage:
 *   1. Start the emulator in one terminal:
 *      npm run serve
 *      (or: firebase emulators:start --only functions,firestore,auth)
 *
 *   2. Run this test script in another terminal:
 *      node test/test_real_sample_gemini.js
 *
 * Optional: Direct AI mode (tests Gemini SDK directly with sample leaf):
 *   node test/test_real_sample_gemini.js --direct
 */

const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

// Sample image path
const SAMPLE_IMAGE_PATH = path.join(__dirname, 'sample_leaf.jpg');

// Default local emulator endpoint for asia-south1
const DEFAULT_EMULATOR_URL =
  process.env.DIAGNOSE_URL || 'http://127.0.0.1:5001/plantii-4fb2e/asia-south1/api/diagnose';

async function runDirectAiTest(imageBuffer) {
  const { analyzeCropLeaf } = require('../services/aiService');
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    console.error('\n❌ GEMINI_API_KEY environment variable is not set for --direct mode.');
    console.error('Please run: $env:GEMINI_API_KEY="your_api_key"; node test/test_real_sample_gemini.js --direct');
    process.exit(1);
  }

  console.log('\n--- Direct AI Vision Test with Google Gemini ---');
  console.log(`Image Size: ${(imageBuffer.length / 1024).toFixed(1)} KB`);
  console.log('Sending sample leaf directly to Gemini AI model...');

  try {
    const startTime = Date.now();
    const result = await analyzeCropLeaf({
      apiKey,
      imageBuffer,
      mimeType: 'image/jpeg',
      crop: 'tomato',
      language: 'en',
    });
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log(`\n✅ Gemini Diagnosis Received in ${elapsed}s:`);
    console.log('====================================================');
    console.log(`Disease Name:       ${result.diseaseName}`);
    console.log(`Scientific Name:    ${result.scientificName}`);
    console.log(`Severity:           ${result.severity}`);
    console.log(`Confidence:         ${result.confidence}`);
    console.log(`Photo Quality:      ${result.photoQuality}`);
    console.log(`Description:        ${result.description}`);
    console.log(`Immediate Actions:  ${result.immediateActions.join(' | ')}`);
    console.log(`Organic Remedies:   ${result.organicTreatments.join(' | ')}`);
    console.log(`Chemical Controls:  ${result.chemicalTreatments.join(' | ')}`);
    console.log(`Safety Note:        ${result.safetyNote}`);
    console.log(`Prevention Tips:    ${result.prevention.join(' | ')}`);
    console.log(`Possible Causes:    ${result.possibleCauses.join(' | ')}`);
    console.log('====================================================\n');
  } catch (err) {
    console.error(`\n❌ Gemini Vision Analysis Failed: [${err.code || 'UNKNOWN'}] ${err.message}`);
    process.exit(1);
  }
}

async function sendToEmulatorEndpoint(imageBuffer) {
  const url = new URL(DEFAULT_EMULATOR_URL);
  const base64Image = imageBuffer.toString('base64');

  const payload = JSON.stringify({
    crop: 'tomato',
    language: 'en',
    image: base64Image,
  });

  const options = {
    hostname: url.hostname,
    port: url.port || (url.protocol === 'https:' ? 443 : 80),
    path: url.pathname,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
      Authorization: 'Bearer test-token-demo_farmer_user_1',
    },
    timeout: 60000,
  };

  const client = url.protocol === 'https:' ? https : http;

  console.log('\n--- Sending Real Sample Leaf to Emulator /diagnose ---');
  console.log(`Target Endpoint: ${DEFAULT_EMULATOR_URL}`);
  console.log(`Sample Image:    ${SAMPLE_IMAGE_PATH} (${(imageBuffer.length / 1024).toFixed(1)} KB)`);
  console.log('Dispatching request with test authentication token...\n');

  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    const req = client.request(options, (res) => {
      let rawData = '';
      res.on('data', (chunk) => (rawData += chunk));
      res.on('end', () => {
        const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
        console.log(`HTTP Status: ${res.statusCode} (${elapsed}s)`);

        try {
          const json = JSON.parse(rawData);
          if (res.statusCode === 200) {
            console.log('\n✅ Diagnosis Result Received from Backend:');
            console.log('====================================================');
            console.log(`Scan ID:            ${json.id}`);
            console.log(`Target Crop:        ${json.cropId}`);
            console.log(`Disease Name:       ${json.diseaseName}`);
            console.log(`Scientific Name:    ${json.scientificName}`);
            console.log(`Severity:           ${json.severity}`);
            console.log(`Confidence:         ${json.confidence || json.confidenceLevel}`);
            console.log(`Photo Quality:      ${json.photoQuality}`);
            console.log(`Description:        ${json.description}`);
            console.log(`Immediate Actions:  ${(json.immediateActions || []).join(' | ')}`);
            console.log(`Organic Remedies:   ${(json.organicTreatments || []).join(' | ')}`);
            console.log(`Chemical Controls:  ${(json.chemicalTreatments || []).join(' | ')}`);
            console.log(`Safety Note:        ${json.safetyNote}`);
            console.log(`Prevention Tips:    ${(json.prevention || json.preventionTips || []).join(' | ')}`);
            console.log(`Possible Causes:    ${(json.possibleCauses || []).join(' | ')}`);
            console.log('====================================================\n');
            resolve(json);
          } else {
            console.log('\n⚠️ Server returned error response:');
            console.log(JSON.stringify(json, null, 2));
            resolve(json);
          }
        } catch (parseErr) {
          console.log(`Raw response: ${rawData}`);
          resolve(rawData);
        }
      });
    });

    req.on('error', (err) => {
      if (err.code === 'ECONNREFUSED') {
        console.error(`\n❌ Could not connect to emulator at ${DEFAULT_EMULATOR_URL}`);
        console.error('Please start the Firebase emulator first in another terminal:');
        console.error('  cd functions');
        console.error('  npm run serve');
        console.error('\nOr test the AI service directly with:');
        console.error('  node test/test_real_sample_gemini.js --direct\n');
      } else {
        console.error(`\n❌ Request error: ${err.message}`);
      }
      reject(err);
    });

    req.on('timeout', () => {
      req.destroy();
      console.error('\n❌ Request timed out after 60 seconds.');
      reject(new Error('Request timed out'));
    });

    req.write(payload);
    req.end();
  });
}

async function main() {
  if (!fs.existsSync(SAMPLE_IMAGE_PATH)) {
    console.error(`Sample image not found at ${SAMPLE_IMAGE_PATH}`);
    process.exit(1);
  }

  const imageBuffer = fs.readFileSync(SAMPLE_IMAGE_PATH);

  if (process.argv.includes('--direct')) {
    await runDirectAiTest(imageBuffer);
  } else {
    try {
      await sendToEmulatorEndpoint(imageBuffer);
    } catch (e) {
      process.exit(1);
    }
  }
}

main();
