const express = require('express');
const { authenticate, requireAdmin } = require('../../middleware/auth');
const orderController = require('../../controllers/order.controller');

const router = express.Router();
router.use(authenticate, requireAdmin);

router.get('/stats/counts', orderController.getOrderCounts);
router.get('/stats/dashboard', orderController.getDashboardStats);
router.get('/', orderController.adminGetOrders);
router.get('/:id', orderController.adminGetOrderDetail);
router.patch('/:id/status', orderController.adminUpdateOrderStatus);

module.exports = router;
