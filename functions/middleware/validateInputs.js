/**
 * Input Validation Middleware
 *
 * Enforces validation for supported languages.
 * Crops are auto-identified by AI.
 */

const limits = require('../config/limits');

function validateDiagnoseInputs(req, res, next) {
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';

  // Language validation
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

  next();
}

module.exports = {
  validateDiagnoseInputs,
};
