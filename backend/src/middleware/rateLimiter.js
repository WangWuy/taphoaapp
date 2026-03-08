const rateLimit = require('express-rate-limit');

// Global: 100 requests per 15 minutes per IP
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: { status: 'error', message: 'Quá nhiều request. Vui lòng thử lại sau.' },
});

// Auth: 5 requests per 15 minutes per IP (login, register, forgot-password)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    standardHeaders: true,
    legacyHeaders: false,
    message: { status: 'error', message: 'Quá nhiều lần thử. Vui lòng đợi 15 phút.' },
});

// Upload: 10 requests per 15 minutes per IP
const uploadLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    standardHeaders: true,
    legacyHeaders: false,
    message: { status: 'error', message: 'Quá nhiều file upload. Vui lòng thử lại sau.' },
});

module.exports = { globalLimiter, authLimiter, uploadLimiter };
