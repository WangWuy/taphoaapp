const express = require('express');
const { authenticate, requireAdmin } = require('../../middleware/auth');
const customerController = require('../../controllers/customer.controller');

const router = express.Router();
router.use(authenticate, requireAdmin);

router.get('/', customerController.listCustomers);
router.get('/:id', customerController.getCustomerDetail);

module.exports = router;
