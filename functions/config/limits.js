/**
 * Centralized Configuration Limits for Plantii Backend
 *
 * ALL limits and operational parameters are defined here.
 * Modify values in this file without changing underlying business logic.
 */

module.exports = {
  // 1. Daily Limit Per User
  userDailyLimit: 10,                 // Max scans allowed per user per calendar day
  timezone: 'Asia/Kolkata',           // Reset timezone (midnight in Asia/Kolkata)

  // 2. Image Limits
  maxImageBytes: 1.5 * 1024 * 1024,   // 1.5 MB after decoding (1,572,864 bytes)
  allowedMimeTypes: [
    'image/jpeg',
    'image/png',
  ],
  expressBodyLimit: '4mb',            // Early rejection threshold for Express JSON/urlencoded

  // 3. Cloud Function Settings & Timeouts
  timeoutSeconds: 60,                 // Function execution timeout in seconds
  memory: '512MiB',                   // Allocated RAM
  maxInstances: 10,                   // Stops runaway concurrency and billing spikes
  region: 'asia-south1',              // Deployment region (Mumbai) for ultra-low latency in India
  // Gemini models: Ordered list (primary and one fallback)
  // If the primary experiences 503 or overload, the fallback is attempted within the same timeout budget
  geminiModels: [
    process.env.GEMINI_MODEL || 'gemini-3.5-flash',
    process.env.GEMINI_FALLBACK_MODEL || 'gemini-3-flash-preview',
  ],
  geminiModel: process.env.GEMINI_MODEL || 'gemini-3.5-flash',
  geminiTimeoutMs: 45000,             // 45s timeout for Gemini API call (leaves 15s buffer)

  // 4. Global Daily Cap (Emergency brake across all users)
  globalDailyCap: 2000,               // Max total scans allowed per day across all users

  // 5. Per-IP Rate Limit
  perIpHourlyLimit: 30,               // Max requests allowed per IP per hour
  ipWindowMs: 60 * 60 * 1000,         // 1-hour rolling window
  ipSalt: process.env.IP_HASH_SALT || 'plantii_ip_salt_2026', // Salt for one-way SHA-256 hash

  // 6. Firebase App Check Enforcement
  // Set to true to strictly reject requests without a valid App Check token.
  // Set to false for local testing and emulator environments.
  enforceAppCheck: process.env.ENFORCE_APP_CHECK === 'true',

  // 7. Input Validation Lists
  allowedLanguages: ['en', 'hi'],

  // 8. Data Retention & Cleanup Policies
  ipLimitRetentionDays: 2,            // Days before IP limit records are deleted
  statsRetentionDays: 90,             // Days before daily stats records are archived/purged
};
