/**
 * Timezone and Date Utility for Plantii Rate Limiting
 */

const limits = require('../config/limits');

/**
 * Returns the current date string (YYYY-MM-DD) in Asia/Kolkata timezone
 * @param {Date} [date=new Date()]
 * @returns {string} YYYY-MM-DD
 */
function getKolkataDateString(date = new Date()) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: limits.timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

/**
 * Returns ISO string for the next midnight in Asia/Kolkata timezone (when limits reset)
 * @param {Date} [date=new Date()]
 * @returns {string} ISO date string
 */
function getKolkataMidnightReset(date = new Date()) {
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: limits.timezone,
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
  });
  const parts = formatter.formatToParts(date);
  const year = parseInt(parts.find((p) => p.type === 'year').value, 10);
  const month = parseInt(parts.find((p) => p.type === 'month').value, 10);
  const day = parseInt(parts.find((p) => p.type === 'day').value, 10);

  // Next day midnight in IST (UTC+05:30)
  const nextDayMidnightUtc = Date.UTC(year, month - 1, day + 1, 0, 0, 0) - (5.5 * 60 * 60 * 1000);
  return new Date(nextDayMidnightUtc).toISOString();
}

module.exports = {
  getKolkataDateString,
  getKolkataMidnightReset,
};
