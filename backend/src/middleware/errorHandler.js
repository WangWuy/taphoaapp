const logger = require('../utils/logger');
const AppError = require('../utils/AppError');

const errorHandler = (err, req, res, _next) => {
    err.statusCode = err.statusCode || 500;

    // Log error
    if (err.statusCode >= 500) {
        logger.error(`${err.message}`, { stack: err.stack, url: req.originalUrl, method: req.method });
    } else {
        logger.warn(`${err.statusCode} ${err.message}`, { url: req.originalUrl });
    }

    // Sequelize validation error
    if (err.name === 'SequelizeValidationError' || err.name === 'SequelizeUniqueConstraintError') {
        const messages = err.errors?.map(e => e.message).join(', ') || err.message;
        return res.status(400).json({ status: 'error', message: messages });
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ status: 'error', message: 'Token không hợp lệ' });
    }
    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ status: 'error', message: 'Token đã hết hạn' });
    }

    // Operational error — safe to show message
    if (err.isOperational) {
        return res.status(err.statusCode).json({ status: 'error', message: err.message });
    }

    // Programming/unknown error — hide details in production
    res.status(500).json({
        status: 'error',
        message: process.env.NODE_ENV === 'production'
            ? 'Đã xảy ra lỗi hệ thống'
            : err.message,
    });
};

module.exports = errorHandler;
