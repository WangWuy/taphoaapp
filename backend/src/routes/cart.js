const express = require('express');
const { authenticate } = require('../middleware/auth');
const cartController = require('../controllers/cart.controller');

const router = express.Router();
router.use(authenticate);

router.get('/', cartController.getCart);
router.post('/', cartController.addToCart);
router.put('/:id', cartController.updateCartItem);
router.delete('/:id', cartController.deleteCartItem);
router.delete('/', cartController.clearCart);

module.exports = router;
