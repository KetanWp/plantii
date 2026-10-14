/**
 * Image Parsing and Validation Middleware
 *
 * Supports both base64 JSON payload and multipart/form-data.
 * Rejects images over 1.5 MB (configurable via config/limits.js) or not JPEG / PNG.
 * Checks real file signature (magic bytes) to ensure authenticity.
 * Returns code 'bad_image' with friendly bilingual message.
 */

const Busboy = require('busboy');
const limits = require('../config/limits');
const { safeLogger } = require('./sanitizeLogs');

/**
 * Checks real file signature (magic bytes) to verify JPEG or PNG format
 * @param {Buffer} buffer
 * @returns {'image/jpeg' | 'image/png' | null}
 */
function detectImageMimeType(buffer) {
  if (!buffer || buffer.length < 8) return null;

  // JPEG magic bytes: FF D8 FF
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg';
  }

  // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
  if (
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47 &&
    buffer[4] === 0x0d &&
    buffer[5] === 0x0a &&
    buffer[6] === 0x1a &&
    buffer[7] === 0x0a
  ) {
    return 'image/png';
  }

  return null;
}

/**
 * Parses raw base64 string or data URI into a Buffer
 * @param {string} str
 * @returns {Buffer | null}
 */
function parseBase64ToBuffer(str) {
  if (typeof str !== 'string' || !str.trim()) return null;

  // Strip data:image/...;base64, prefix if present
  const base64Data = str.includes(',') ? str.split(',')[1] : str;
  try {
    return Buffer.from(base64Data, 'base64');
  } catch (err) {
    return null;
  }
}

/**
 * Middleware that parses image from JSON base64 or multipart/form-data
 */
function parseAndValidateImage(req, res, next) {
  const contentType = req.headers['content-type'] || '';
  const isHindi = req.body?.language === 'hi' || req.query?.language === 'hi';
  const maxBytes = limits.maxImageBytes;
  const maxMbStr = (maxBytes / (1024 * 1024)).toFixed(1).replace(/\.0$/, '');

  const badImageError = (msgEn, msgHi) => {
    return res.status(400).json({
      error: {
        code: 'bad_image',
        message: isHindi ? msgHi : msgEn,
      },
    });
  };

  // Case 1: multipart/form-data
  if (contentType.includes('multipart/form-data')) {
    let busboy;
    try {
      busboy = Busboy({
        headers: req.headers,
        limits: {
          fileSize: maxBytes,
          files: 1,
        },
      });
    } catch (err) {
      safeLogger.error('Failed to initialize Busboy', { message: err.message });
      return badImageError('Invalid multipart request.', 'अमान्य मल्टीपार्ट अनुरोध।');
    }

    const fields = {};
    const fileBufferChunks = [];
    let fileTruncated = false;

    busboy.on('field', (fieldname, val) => {
      fields[fieldname] = val;
    });

    busboy.on('file', (fieldname, file) => {
      file.on('data', (data) => {
        fileBufferChunks.push(data);
      });

      file.on('limit', () => {
        fileTruncated = true;
      });
    });

    busboy.on('finish', () => {
      req.body = { ...req.body, ...fields };
      const currentIsHindi = req.body.language === 'hi';

      if (fileTruncated) {
        return res.status(400).json({
          error: {
            code: 'bad_image',
            message: currentIsHindi
              ? `छवि का आकार ${maxMbStr}MB से अधिक है। कृपया ${maxMbStr}MB से छोटी छवि चुनें।`
              : `Image size exceeds the ${maxMbStr} MB limit. Please select a smaller image.`,
          },
        });
      }

      let buffer = Buffer.concat(fileBufferChunks);

      if (buffer.length === 0 && fields.image) {
        buffer = parseBase64ToBuffer(fields.image);
      }

      if (!buffer || buffer.length === 0) {
        return res.status(400).json({
          error: {
            code: 'bad_image',
            message: currentIsHindi
              ? 'कोई पौधा छवि नहीं मिली। कृपया एक छवि प्रदान करें।'
              : 'No image provided. Please upload an image of the plant leaf.',
          },
        });
      }

      if (buffer.length > maxBytes) {
        return res.status(400).json({
          error: {
            code: 'bad_image',
            message: currentIsHindi
              ? `छवि का आकार ${maxMbStr}MB से अधिक है। कृपया ${maxMbStr}MB से छोटी छवि चुनें।`
              : `Image size exceeds the ${maxMbStr} MB limit. Please select a smaller image.`,
          },
        });
      }

      const detectedMime = detectImageMimeType(buffer);
      if (!detectedMime || !limits.allowedMimeTypes.includes(detectedMime)) {
        return res.status(400).json({
          error: {
            code: 'bad_image',
            message: currentIsHindi
              ? 'केवल JPEG और PNG प्रारूप समर्थित हैं। कृपया एक वैध छवि अपलोड करें।'
              : 'Only JPEG and PNG formats are supported. Please upload a valid image.',
          },
        });
      }

      req.parsedImage = {
        buffer,
        mimeType: detectedMime,
        sizeBytes: buffer.length,
      };

      next();
    });

    busboy.on('error', (err) => {
      safeLogger.error('Busboy error processing multipart stream', { message: err.message });
      return badImageError('Error processing image upload.', 'छवि अपलोड संसाधित करने में त्रुटि।');
    });

    if (req.rawBody) {
      busboy.end(req.rawBody);
    } else {
      req.pipe(busboy);
    }
    return;
  }

  // Case 2: JSON payload with base64 image
  const rawImage = req.body?.image;
  if (!rawImage) {
    return badImageError(
      'No image provided. Please upload an image of the plant leaf.',
      'कोई पौधा छवि नहीं मिली। कृपया एक छवि प्रदान करें।'
    );
  }

  const buffer = parseBase64ToBuffer(rawImage);
  if (!buffer || buffer.length === 0) {
    return badImageError(
      'Invalid base64 image data.',
      'अमान्य बेस64 छवि डेटा।'
    );
  }

  if (buffer.length > maxBytes) {
    return res.status(400).json({
      error: {
        code: 'bad_image',
        message: isHindi
          ? `छवि का आकार ${maxMbStr}MB से अधिक है। कृपया ${maxMbStr}MB से छोटी छवि चुनें।`
          : `Image size exceeds the ${maxMbStr} MB limit. Please select a smaller image.`,
      },
    });
  }

  const detectedMime = detectImageMimeType(buffer);
  if (!detectedMime || !limits.allowedMimeTypes.includes(detectedMime)) {
    return badImageError(
      'Only JPEG and PNG formats are supported. Please upload a valid image.',
      'केवल JPEG और PNG प्रारूप समर्थित हैं। कृपया एक वैध छवि अपलोड करें।'
    );
  }

  req.parsedImage = {
    buffer,
    mimeType: detectedMime,
    sizeBytes: buffer.length,
  };

  next();
}

module.exports = {
  parseAndValidateImage,
  detectImageMimeType,
  parseBase64ToBuffer,
  MAX_IMAGE_BYTES: limits.maxImageBytes,
};
