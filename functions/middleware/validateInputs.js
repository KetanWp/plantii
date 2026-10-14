/**
 * Input Validation Middleware
 *
 * Enforces strict validation for crop types and languages against allowed lists.
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

  // 2. Crop validation
  const rawCrop = req.body?.crop;
  if (!rawCrop || typeof rawCrop !== 'string' || !rawCrop.trim()) {
    return res.status(400).json({
      error: {
        code: 'bad_request',
        message: isHindi
          ? 'फसल का नाम (crop) आवश्यक है।'
          : 'Crop parameter is required.',
      },
    });
  }

  const crop = rawCrop.toLowerCase().trim();
  if (!limits.allowedCrops.includes(crop)) {
    return res.status(400).json({
      error: {
        code: 'bad_request',
        message: isHindi
          ? `अमान्य फसल "${rawCrop}"। समर्थित फसलें: ${limits.allowedCrops.join(', ')}`
          : `Unsupported crop type "${rawCrop}". Supported crops: ${limits.allowedCrops.join(', ')}`,
      },
    });
  }

  req.body.crop = crop;
  next();
}

module.exports = {
  validateDiagnoseInputs,
};
