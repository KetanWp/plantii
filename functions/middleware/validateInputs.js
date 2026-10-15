/**
 * Input Validation Middleware
 *
 * Enforces validation for languages, optional cropHint, and forceRefresh flags.
 * Does NOT require or validate crop type (crops are auto-identified by AI).
 */

const limits = require('../config/limits');

function validateDiagnoseInputs(req, res, next) {
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';

  // 1. Language validation
  const rawLang = req.body?.language;
  if (rawLang !== undefined && rawLang !== null) {
    const langStr = String(rawLang).toLowerCase().trim();
    if (!limits.allowedLanguages.includes(langStr)) {
      return res.status(400).json({
        error: {
          code: 'bad_request',
          message: isHindi
            ? `अमान्य भाषा "${rawLang}"। समर्थित भाषाएं: ${limits.allowedLanguages.join(', ')}`
            : `Invalid language "${rawLang}". Supported languages: ${limits.allowedLanguages.join(', ')}`,
        },
      });
    }
    req.body.language = langStr;
  } else {
    req.body.language = 'en';
  }

  // 2. Optional cropHint validation (item 7d)
  const rawCropHint = req.body?.cropHint;
  if (rawCropHint !== undefined && rawCropHint !== null && String(rawCropHint).trim().length > 0) {
    req.body.cropHint = String(rawCropHint).trim().substring(0, 50);
  } else {
    req.body.cropHint = '';
  }

  // 3. Optional forceRefresh flag (item 7b)
  req.body.forceRefresh = Boolean(req.body?.forceRefresh === true || req.body?.forceRefresh === 'true');

  next();
}

module.exports = {
  validateDiagnoseInputs,
};
