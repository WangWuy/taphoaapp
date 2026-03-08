const jwt = require('jsonwebtoken');
const { User } = require('../models');
const AppError = require('../utils/AppError');

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET || JWT_SECRET.includes('dev-jwt-secret')) {
    const logger = require('../utils/logger');
    logger.warn('⚠️  JWT_SECRET is using default/weak value. Set a strong secret in production!');
}

// Middleware: Verify JWT access token
const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new AppError('Token không hợp lệ', 401);
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, JWT_SECRET || 'dev-jwt-secret-fallback');

        const user = await User.findByPk(decoded.userId);
        if (!user || !user.is_active) {
            throw new AppError('Tài khoản không tồn tại hoặc đã bị khóa', 401);
        }

        req.user = user;
        req.userId = user.id;
        next();
    } catch (error) {
        if (error.isOperational) return next(error);
        if (error.name === 'TokenExpiredError') {
            return next(new AppError('Token đã hết hạn', 401));
        }
        return next(new AppError('Token không hợp lệ', 401));
    }
};

// Middleware: Check admin role
const requireAdmin = (req, res, next) => {
    if (req.user.role !== 'admin') {
        return next(new AppError('Bạn không có quyền truy cập', 403));
    }
    next();
};

// Generate short-lived access token (15 minutes)
const generateAccessToken = (userId) => {
    return jwt.sign({ userId }, JWT_SECRET || 'dev-jwt-secret-fallback', {
        expiresIn: process.env.ACCESS_TOKEN_EXPIRES_IN || '15m',
    });
};

// Backward compat alias
const generateToken = generateAccessToken;

module.exports = { authenticate, requireAdmin, generateAccessToken, generateToken };
