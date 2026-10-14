# Plantii Backend (Firebase Cloud Functions 2nd Gen)

A hardened, production-ready serverless backend built with **Node.js**, **Express**, and **Firebase Cloud Functions (2nd Gen)** for AI-powered plant leaf disease diagnosis.

---

## Hardened Security & Rate Limiting Protections

All limits and operational thresholds are centralized in a single configuration file:  
📁 [**`functions/config/limits.js`**](./config/limits.js)  
You can tune any number or behavior without touching business logic!

| Protection | Config Key | Default | Description |
|---|---|---|---|
| **Daily Limit per User** | `userDailyLimit` | `10` scans / day | Tracked via Firestore transaction on `users/{uid}` with fields `scanCount` & `scanDate` in `Asia/Kolkata` timezone. Automatically resets to 0 on a new day. Only counted when the AI call is about to be made. Returns HTTP 429 (`rate_limited`) with `limit` and `resetsAt`. |
| **Scan Count Refund** | Automatic | Enabled | If the AI call fails or times out, the user's daily count and global daily count are immediately refunded. |
| **Image Size Limit** | `maxImageBytes` | `1.5 MB` (1,572,864 bytes) | Rejects decoded images larger than 1.5 MB with HTTP 400 (`bad_image`). |
| **Magic Bytes Verification** | `allowedMimeTypes` | `['image/jpeg', 'image/png']` | Verifies the real file signature (magic bytes: `FF D8 FF` for JPEG, `89 50 4E 47 0D 0A 1A 0A` for PNG). Blocks disguised PDFs, text, or executables. |
| **Express Body Limit** | `expressBodyLimit` | `'4mb'` | Express body-parser early rejection threshold to stop oversized network uploads early. |
| **Global Daily Cap** | `globalDailyCap` | `2000` scans / day | Emergency brake tracked across all users in Firestore doc `stats/{date}` via transactions. Returns HTTP 503 (`service_busy`) when reached. |
| **Per-IP Rate Limit** | `perIpHourlyLimit` | `30` reqs / hour | Tracked in `ip_limits` with one-way SHA-256 hashed IPs (`ipSalt`). Raw IPs are NEVER stored. Returns HTTP 429 (`rate_limited`). |
| **App Check Enforcement** | `enforceAppCheck` | `false` (default) | Enforces Firebase App Check on `/diagnose` and `/feedback`. Easily toggled in `limits.js` or with `ENFORCE_APP_CHECK=true` environment variable. |
| **Gemini AI Timeout** | `geminiTimeoutMs` | `45000` (45s) | Hard timeout on the Gemini Vision call so the function returns a clean HTTP 504 (`timeout`) before the 60s Cloud Function terminates. |
| **Cloud Function RAM** | `memory` | `'512MiB'` | Cloud Run instance RAM allocation. |
| **Concurrency Cap** | `maxInstances` | `10` | Maximum instances to prevent runaway auto-scaling and unexpected Google Cloud bills. |
| **Deployment Region** | `region` | `'asia-south1'` | Deployed in Mumbai for lowest latency to users in India. |
| **Input Validation** | `allowedCrops`, `allowedLanguages` | Curated Lists | Rejects unsupported crops or languages (`en` or `hi`) with HTTP 400 (`bad_request`). |
| **Zero-Leak Logging** | Sanitizer | Enabled | Never logs images, buffers, base64 strings, API keys, Bearer tokens, or full AI responses. |
| **Data Cleanup** | `cleanupExpiredRateLimits` | Daily Cron | Scheduled 2nd gen function running every 24 hours to delete expired IP records older than `ipLimitRetentionDays` (2 days). |

---

## How to Change Limits

Open [`functions/config/limits.js`](./config/limits.js) and update the values:

```javascript
module.exports = {
  // Change daily scans per user (e.g. increase to 20):
  userDailyLimit: 20,

  // Change image limit (e.g. increase to 2 MB):
  maxImageBytes: 2 * 1024 * 1024,

  // Change global emergency cap (e.g. increase to 5000):
  globalDailyCap: 5000,

  // Change per-IP hourly rate limit:
  perIpHourlyLimit: 50,

  // Enable App Check enforcement in production:
  enforceAppCheck: true,

  // Add more allowed crops:
  allowedCrops: ['tomato', 'potato', 'rice', 'wheat', 'cotton', 'chilli', 'mango'],
};
```

After modifying limits, redeploy the Cloud Functions:
```powershell
firebase deploy --only functions
```

---

## Directory Structure

```text
functions/
├── config/
│   └── limits.js               # Centralized configuration limits
├── utils/
│   └── timezone.js             # Asia/Kolkata date calculations & midnight resetsAt
├── middleware/
│   ├── auth.js                 # Firebase Auth ID Token verification
│   ├── appCheck.js             # Firebase App Check verification (with toggle flag)
│   ├── ipRateLimiter.js        # Per-IP rate limiting with SHA-256 hashed IPs
│   ├── validateInputs.js       # Strict validation for crops & languages
│   ├── imageParser.js          # Magic bytes verification & 1.5 MB decode limit
│   └── sanitizeLogs.js         # Redaction of images, API keys & full AI responses
├── services/
│   ├── aiService.js            # Gemini Vision AI with official @google/genai SDK, structured JSON output, retry & timeouts
│   ├── scanQuotaService.js     # User daily limit & global cap transactions + refunds
│   └── firestoreService.js     # Scans & feedback persistence
├── routes/
│   ├── diagnose.js             # POST /diagnose handler with quota checks & refunds
│   └── feedback.js             # POST /feedback handler with scan ownership verification
├── prompts/
│   └── diagnosis.js            # Pathologist prompt templates (English & Hindi)
├── index.js                    # 2nd gen entrypoint & scheduled cleanup function
└── test/
    ├── sample_leaf.jpg         # Real sample tomato early blight leaf photo (800KB)
    ├── test_units.js           # Prompts, schemas, magic bytes, and sanitizer unit tests
    ├── test_security_hardening.js # Mandatory security tests (11th scan block, refund, etc.)
    └── test_real_sample_gemini.js # End-to-end sample leaf test script for emulator & direct AI
```

---

## Running the Automated Tests

### 1. Run Unit & Security Hardening Tests:
```powershell
cd functions
npm test
```

### 2. Run Real Sample Leaf Diagnosis Test (Local Emulator):
Start the Firebase emulator in one terminal:
```powershell
cd functions
npm run serve
# (runs: firebase emulators:start --only functions,firestore,auth)
```
In a second terminal, send the real sample leaf photo:
```powershell
cd functions
node test/test_real_sample_gemini.js
```

### 3. Run Direct AI Diagnosis Test (Live Gemini API):
To test the Google Gemini API with the sample leaf directly:
```powershell
cd functions
$env:GEMINI_API_KEY = (firebase functions:secrets:access GEMINI_API_KEY).Trim()
node test/test_real_sample_gemini.js --direct
```

---

## Deploying to Production

Ensure the secret `GEMINI_API_KEY` is configured in Firebase Secret Manager:
```powershell
firebase functions:secrets:set GEMINI_API_KEY
```

Then deploy the Cloud Functions:
```powershell
firebase deploy --only functions
```

## API Endpoints

### 1. `POST /diagnose`
Analyzes a crop leaf photo and returns plant pathology diagnosis and treatments.

- **Headers**:
  - `Authorization`: `Bearer <FIREBASE_AUTH_ID_TOKEN>`
  - `X-Firebase-AppCheck`: `<APP_CHECK_TOKEN>` (optional in dev, required when `enforceAppCheck: true`)
  - `Content-Type`: `application/json` OR `multipart/form-data`
- **Body Parameters**:
  - `image` (string or file): Base64 data string or image file upload (JPEG or PNG, $\le 1.5\text{ MB}$).
  - `crop` (string): Crop type from `allowedCrops` (e.g. `tomato`, `potato`, `rice`, `wheat`, `cotton`).
  - `language` (string): Output language (`"en"` or `"hi"`).
- **Success Response (HTTP 200)**:
```json
{
  "id": "scan_doc_id",
  "cropId": "tomato",
  "diseaseName": "Early Blight (अगेती झुलसा)",
  "scientificName": "Alternaria solani",
  "severity": "moderate",
  "confidenceLevel": "High",
  "description": "Brown concentric spots with target-board appearance on lower leaves.",
  "immediateActions": [
    "Prune and destroy infected leaves immediately",
    "Avoid overhead sprinkler irrigation"
  ],
  "organicTreatments": [
    "Spray 5% neem seed kernel extract (NSKE)",
    "Apply Trichoderma harzianum bio-fungicide"
  ],
  "chemicalTreatments": [
    "Mancozeb 75% WP @ 2g per liter of water",
    "Chlorothalonil @ 2g per liter of water"
  ],
  "safetyNote": "Wear rubber gloves and a face mask while spraying.",
  "preventionTips": [
    "Practice 2-year crop rotation",
    "Ensure proper plant spacing for air circulation"
  ],
  "language": "en"
}
```

- **Error Responses**:
  - `400 bad_image`: Oversized image (>1.5MB) or wrong file format.
  - `400 bad_request`: Invalid crop or language.
  - `401 unauthorized`: Missing or invalid Bearer auth token.
  - `401 app_check_failed`: Missing or invalid App Check token (when enforced).
  - `429 rate_limited`: User daily limit reached (10 scans) or IP hourly limit reached (30 reqs). Includes `resetsAt`.
  - `502 ai_failed`: Gemini Vision was unable to parse the image. (Quota refunded).
  - `503 service_busy`: Global emergency brake reached (2000 total scans/day).
  - `504 timeout`: Gemini AI processing exceeded 45 seconds. (Quota refunded).

---

### 2. `POST /feedback`
Records thumbs up / thumbs down feedback for a previously diagnosed scan.

- **Headers**:
  - `Authorization`: `Bearer <FIREBASE_AUTH_ID_TOKEN>`
  - `X-Firebase-AppCheck`: `<APP_CHECK_TOKEN>`
  - `Content-Type`: `application/json`
- **Body**:
```json
{
  "scanId": "scan_doc_id",
  "helpful": true,
  "comment": "Very accurate treatment advice"
}
```

---

### 3. `GET /health`
Liveness probe returning service status, active region, and current limits.
