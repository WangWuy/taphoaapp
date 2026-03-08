const express = require('express');
const { authenticate } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');
const validate = require('../middleware/validate');
const authValidator = require('../validators/auth.validator');
const authController = require('../controllers/auth.controller');

const router = express.Router();

// Public (rate limited)
router.post('/register', authLimiter, validate(authValidator.register), authController.register);
router.post('/login', authLimiter, validate(authValidator.login), authController.login);
router.post('/refresh', validate(authValidator.refreshToken), authController.refresh);
router.post('/logout', authController.logout);

// Forgot password flow (rate limited)
router.post('/forgot-password', authLimiter, validate(authValidator.forgotPassword), authController.forgotPassword);
router.post('/verify-otp', authLimiter, validate(authValidator.verifyOTP), authController.verifyOTP);
router.post('/reset-password', validate(authValidator.resetPassword), authController.resetPassword);

// Authenticated
router.get('/me', authenticate, authController.getMe);
router.patch('/profile', authenticate, validate(authValidator.updateProfile), authController.updateProfile);
router.patch('/password', authenticate, validate(authValidator.changePassword), authController.changePassword);
router.post('/logout-all', authenticate, authController.logoutAll);

module.exports = router;
