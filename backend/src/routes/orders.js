const express = require('express');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');
const orderValidator = require('../validators/order.validator');
const orderController = require('../controllers/order.controller');

const router = express.Router();
router.use(authenticate);

router.post('/', validate(orderValidator.createOrder), orderController.createOrder);
router.get('/', orderController.getUserOrders);
router.get('/:id', orderController.getOrderDetail);
router.patch('/:id/cancel', orderController.cancelOrder);
router.patch('/:id/confirm-delivery', orderController.confirmDelivery);

module.exports = router;
