const express = require('express');
const { authenticate, requireAdmin } = require('../../middleware/auth');
const reportController = require('../../controllers/report.controller');

const router = express.Router();
router.use(authenticate, requireAdmin);

router.get('/revenue', reportController.getRevenue);
router.get('/top-products', reportController.getTopProducts);
router.get('/top-customers', reportController.getTopCustomers);
router.get('/order-stats', reportController.getOrderStats);
router.get('/inventory-alerts', reportController.getInventoryAlerts);

module.exports = router;
