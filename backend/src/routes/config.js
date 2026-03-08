const express = require('express');
const { authenticate, requireAdmin } = require('../middleware/auth');
const configController = require('../controllers/config.controller');

const router = express.Router();

router.get('/', configController.getConfig);
router.put('/', authenticate, requireAdmin, configController.updateConfig);

module.exports = router;
