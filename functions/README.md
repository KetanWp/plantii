# Crop Doctor Backend (Firebase Cloud Functions 2nd Gen)

A secure, production-ready backend built with **Node.js**, **Express**, and **Firebase Cloud Functions (2nd Gen)** for AI-powered plant leaf disease diagnosis.

---

## Architecture & Features

- **Express on Cloud Functions 2nd Gen**: Scalable serverless API powered by Cloud Run infrastructure.
- **AI Vision Integration**: Google Gemini Vision API (`gemini-1.5-flash`) with structured JSON schema enforcement.
- **Editable Prompt**: Isolated in [`prompts/diagnosis.js`](./prompts/diagnosis.js) for effortless tweaking.
- **Fail-Safe Self-Healing**: Automated single retry if the model returns malformed JSON.
- **Image Protection**: Enforces $< 2\text{ MB}$ file size and verifies JPEG/PNG magic bytes.
- **Daily Rate Limiting**: Caps scans at **10 scans per user per calendar day** using atomic Firestore transactions. Includes automatic slot rollback if the AI fails.
- **60-Second Timeout Handling**: Application-level timeout race returning code `timeout` before function termination.
- **Firestore Security**: Scans are stored in `scans`; client rules permit **read-only access to own scans** with **zero client writes**. Feedback stored in `feedback`.
- **Zero-Leak Logging**: Images, buffers, base64 strings, and API keys are automatically redacted.

---

## Directory Structure

```text
functions/
├── index.js                     # 2nd gen entrypoint & Express API routing
├── package.json                 # Dependencies & scripts
├── firestore.rules              # (In project root) Security rules
├── firebase.json                # (In project root) Emulator & function config
├── prompts/
│   └── diagnosis.js             # Customizable AI vision pathologist prompt
├── middleware/
│   ├── auth.js                  # Bearer token verification via Firebase Admin
│   ├── rateLimiter.js           # 10 scans/day limit with Firestore transactions
│   ├── imageParser.js           # Base64 & multipart parser with magic bytes check
│   └── sanitizeLogs.js          # Sensitive data redaction for zero-leak logging
├── services/
│   ├── aiService.js             # Gemini Vision client, Zod schema & 1x retry
│   └── firestoreService.js      # Scans & feedback persistence
├── routes/
│   ├── diagnose.js              # POST /diagnose handler with 60s timeout
│   └── feedback.js              # POST /feedback with scan ownership verification
└── test/
    └── test_units.js            # Automated unit tests
```

---

## Endpoints

### 1. `POST /diagnose`
Analyzes a crop leaf photo and returns detailed diagnosis and treatment steps.

- **Headers**:
  - `Authorization`: `Bearer <FIREBASE_AUTH_ID_TOKEN>`
  - `Content-Type`: `application/json` OR `multipart/form-data`
- **Body Parameters**:
  - `image` (string or file): Base64 data string or file upload (JPEG or PNG, $\le 2\text{ MB}$).
  - `crop` (string): Crop type (e.g. `tomato`, `potato`, `rice`).
  - `language` (string): Output language (`"en"` for English, `"hi"` for Hindi).
- **Success Response (200 OK)**:
```json
{
  "id": "scan_doc_id",
  "cropId": "tomato",
  "diseaseName": "Early Blight (अगेती झुलसा)",
  "scientificName": "Alternaria solani",
  "severity": "moderate",
  "confidenceLevel": "High",
  "description": "Brown concentric spots with target-board rings visible on lower foliage.",
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

---

### 2. `POST /feedback`
Records user satisfaction for a specific scan.

- **Headers**:
  - `Authorization`: `Bearer <FIREBASE_AUTH_ID_TOKEN>`
  - `Content-Type`: `application/json`
- **Body Parameters**:
  - `scanId` (string, required): Document ID from `/diagnose`.
  - `helpful` (boolean, required): `true` or `false`.
  - `comment` (string, optional): Feedback text.
- **Success Response (200 OK)**:
```json
{
  "success": true,
  "feedbackId": "feedback_doc_id",
  "message": "Feedback submitted successfully. Thank you!"
}
```

---

## Standard Error Codes

All errors return JSON in this standardized structure:

```json
{
  "error": {
    "code": "rate_limited",
    "message": "Daily scan limit reached (maximum 10 scans per day). Please try again tomorrow."
  }
}
```

| Error Code | HTTP Status | Trigger Condition |
| :--- | :--- | :--- |
| `unauthorized` | 401 | Missing, malformed, or expired Firebase ID token. |
| `bad_image` | 400 | Image exceeds 2 MB, is corrupt, or is not JPEG/PNG. |
| `rate_limited` | 429 | User has reached the 10 scans per calendar day limit. |
| `ai_failed` | 502 | AI vision analysis failed after 1 automatic retry. |
| `timeout` | 504 | Request exceeded 60 seconds. |
| `forbidden` | 403 | Attempting to submit feedback for another user's scan. |
| `not_found` | 404 | Scan record does not exist. |
| `bad_request` | 400 | Missing required fields (e.g. `scanId`, `helpful`). |

---

## Setting Up Firebase Secrets

The AI API key is securely managed using **Firebase Secret Manager** (`defineSecret`) and is **never** committed to source code or logged.

### 1. Set the Secret in Firebase
Run the following command from the project root:

```bash
firebase functions:secrets:set AI_API_KEY
```

When prompted, paste your Google Gemini API key (from Google AI Studio).

### 2. Verify the Secret
```bash
firebase functions:secrets:get AI_API_KEY
```

---

## Local Testing with Firebase Emulator Suite

The project includes preconfigured emulators for **Functions (port 5001)**, **Firestore (port 8080)**, **Auth (port 9099)**, and the **Emulator UI (port 4000)**.

### Step 1: Run Unit Tests
```bash
cd functions
npm test
```

### Step 2: Set Environment Variable for Local Emulation
Create a `.env.local` file inside `functions/` (this file is git-ignored):

```env
AI_API_KEY=your_gemini_api_key_here
```

### Step 3: Start Emulators
From the project root:

```bash
firebase emulators:start --only functions,firestore,auth
```

Or from the `functions/` folder:
```bash
npm run serve
```

Once started:
- **Emulator UI**: Open `http://localhost:4000` in your browser.
- **Function URL**: `http://127.0.0.1:5001/<your-project-id>/us-central1/api`

---

## Testing Endpoints Locally

### 1. Generate a Test Auth Token
In local emulator mode, you can create a test user in the Auth Emulator UI (`http://localhost:4000/auth`) or generate a test ID token using the Firebase Auth REST API or Admin SDK.

### 2. Test `/diagnose` with Base64 JSON (cURL)
```bash
curl -X POST http://127.0.0.1:5001/crop-doctor-app/us-central1/api/diagnose \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "crop": "tomato",
    "language": "en",
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD..."
  }'
```

### 3. Test `/diagnose` with Multipart Form Upload (cURL)
```bash
curl -X POST http://127.0.0.1:5001/crop-doctor-app/us-central1/api/diagnose \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -F "crop=potato" \
  -F "language=hi" \
  -F "image=@/path/to/infected_leaf.jpg;type=image/jpeg"
```

### 4. Test `/feedback` (cURL)
```bash
curl -X POST http://127.0.0.1:5001/crop-doctor-app/us-central1/api/feedback \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "scanId": "SCAN_DOCUMENT_ID_HERE",
    "helpful": true,
    "comment": "Treatment advice worked great on my tomato plants!"
  }'
```

---

## Deploying to Production

When ready to link your live Firebase project and deploy:

### 1. Select / Switch Firebase Project
```bash
firebase use <your-firebase-project-id>
```

### 2. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 3. Deploy Cloud Functions
```bash
firebase deploy --only functions
```

### 4. Monitor Live Production Logs
```bash
firebase functions:log
```
