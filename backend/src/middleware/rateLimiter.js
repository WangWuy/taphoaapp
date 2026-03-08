const rateLimit = require('express-rate-limit');

// Global: 1000 requests per 15 minutes per IP
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1000,
    standardHeaders: true,
    legacyHeaders: false,
    message: { status: 'error', message: 'Quá nhiều request. Vui lòng thử lại sau.' },
});

// Auth: 20 requests per 15 minutes per IP (login, register, forgot-password)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    message: { status: 'error', message: 'Quá nhiều lần thử. Vui lòng đợi 15 phút.' },
});

// Upload: 50 requests per 15 minutes per IP
const uploadLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 50,
    standardHeaders: true,
    legacyHeaders: false,
    message: { status: 'error', message: 'Quá nhiều file upload. Vui lòng thử lại sau.' },
});

module.exports = { globalLimiter, authLimiter, uploadLimiter };
