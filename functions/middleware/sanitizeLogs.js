/**
 * Middleware and utility for safe logging
 * Enforces requirement: "Never log images or API keys."
 */

const { logger } = require('firebase-functions');

/**
 * Strips sensitive data (images, base64 data, authorization tokens, API keys)
 * from any object before logging.
 */
function sanitize(obj, depth = 0) {
  if (depth > 4) return '[MaxDepth]';
  if (obj === null || obj === undefined) return obj;

  if (typeof obj === 'string') {
    // Redact base64 image strings or long payloads
    if (obj.startsWith('data:image/') || (obj.length > 200 && /^[A-Za-z0-9+/=]+$/.test(obj.substring(0, 100)))) {
      return `[REDACTED_IMAGE_DATA (${obj.length} chars)]`;
    }
    // Redact Bearer tokens
    if (obj.startsWith('Bearer ')) {
      return 'Bearer [REDACTED_TOKEN]';
    }
    // Redact API keys if pattern matches
    if (/AIza[0-9A-Za-z-_]{35}/.test(obj)) {
      return '[REDACTED_API_KEY]';
    }
    return obj;
  }

  if (Buffer.isBuffer(obj)) {
    return `[REDACTED_BUFFER (${obj.length} bytes)]`;
  }

  if (Array.isArray(obj)) {
    return obj.map((item) => sanitize(item, depth + 1));
  }

  if (typeof obj === 'object') {
    const cleaned = {};
    for (const [key, val] of Object.entries(obj)) {
      const lowerKey = key.toLowerCase();
      if (lowerKey === 'image' || lowerKey === 'file' || lowerKey === 'buffer' || lowerKey === 'data') {
        cleaned[key] = '[REDACTED_IMAGE_PAYLOAD]';
      } else if (
        lowerKey.includes('key') ||
        lowerKey.includes('secret') ||
        lowerKey.includes('token') ||
        lowerKey.includes('authorization') ||
        lowerKey.includes('password')
      ) {
        cleaned[key] = '[REDACTED_CREDENTIAL]';
      } else {
        cleaned[key] = sanitize(val, depth + 1);
      }
    }
    return cleaned;
  }

  return obj;
}

/**
 * Express middleware to sanitize incoming request logging
 */
function sanitizeRequestLogging(req, res, next) {
  // Safe request logging
  const safeLogInfo = {
    method: req.method,
    url: req.originalUrl || req.url,
    ip: req.ip,
    hasAuthHeader: Boolean(req.headers.authorization),
    contentType: req.headers['content-type'],
  };

  logger.info(`Incoming request: ${req.method} ${safeLogInfo.url}`, safeLogInfo);
  next();
}

/**
 * Safe logger methods that automatically sanitize all arguments
 */
const safeLogger = {
  info: (message, ...meta) => {
    logger.info(message, ...meta.map((m) => sanitize(m)));
  },
  warn: (message, ...meta) => {
    logger.warn(message, ...meta.map((m) => sanitize(m)));
  },
  error: (message, ...meta) => {
    logger.error(message, ...meta.map((m) => sanitize(m)));
  },
};

module.exports = {
  sanitize,
  sanitizeRequestLogging,
  safeLogger,
};
