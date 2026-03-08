const express = require('express');
const { authenticate } = require('../middleware/auth');
const { uploadLimiter } = require('../middleware/rateLimiter');
const uploadController = require('../controllers/upload.controller');

const router = express.Router();

router.post('/', authenticate, uploadLimiter, uploadController.uploadMiddleware, uploadController.uploadImage);
router.use(uploadController.handleMulterError);

module.exports = router;
