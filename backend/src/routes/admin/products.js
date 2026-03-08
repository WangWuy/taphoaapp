const express = require('express');
const { authenticate, requireAdmin } = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const { createProduct, updateProduct, updateStock } = require('../../validators/product.validator');
const productController = require('../../controllers/product.controller');

const router = express.Router();
router.use(authenticate, requireAdmin);

router.get('/inventory', productController.getInventory);
router.get('/', productController.adminListProducts);
router.post('/', validate(createProduct), productController.createProduct);
router.put('/:id', validate(updateProduct), productController.updateProduct);
router.patch('/:id/stock', validate(updateStock), productController.updateStock);
router.delete('/:id', productController.deleteProduct);

module.exports = router;
